module Atlas
  module ActiveDocument
    # Responsible for loading documents from disk, and creating instances of
    # ActiveDocument using the file contents. Keeps track of instances after
    # they are created, and handles lazy loading so that only the documents
    # you need are fetched from disk.
    #
    # Managers persist in memory for the life of the Ruby process; they will
    # not be garbage collected. Therefore, it is not advised to create them
    # manually; leave the indiviual ActiveDocument classes to handle this for
    # you. Supply "false" to the +initialze register+ parameter if you want to
    # disable this (e.g. for testing).
    #
    # Wow! I'm Mr. Manager!
    class Manager
      # Public: Returns the name of the directory in which the files are stored. Manager infers the
      # name from the class when none is explicitly set.
      #
      # Returns a String.
      attr_reader :directory_name

      # Public: Returns the file extension used by files in this manager.
      #
      # Returns a String.
      attr_reader :extension_name

      # Public: Creates a new manager for the given document +klass+.
      #
      # klass    - The ActiveDocument class whose files are read by the
      #            Manager instance.
      # register - Tells the Manager whether to register itself with the
      #            class. This should be set to false if you want to create
      #            managers on-the-fly, but note that its cache will not be
      #            expired if the ETSource data directory is changed.
      #
      # Returns a Manager.
      def initialize(klass, register = true)
        @klass = klass
        @directory_name = klass.name.gsub(/^Atlas::/, '').tableize
        @extension_name = 'ad'

        clear!
        self.class.register(self) if register
      end

      # Public: Fetches a single documents by its +key+.
      #
      # key - The key of the document to retrieve.
      #
      # Returns the document, or nil if the document does not exist.
      def get(key)
        key && (@documents[key.to_sym] ||= load(key.to_sym)) || nil
      end

      # Public: Given a document, deletes it from the disk and the manager.
      #
      # document - The document to be removed.
      #
      # Returns true or false.
      def delete(document)
        delete_path(document.path)
      end

      # Public: Fetches all of the documents.
      #
      # Returns an array of ActiveDocuments.
      def all
        unless @all_loaded
          @all = keys.map { |key| get(key) }
          @all_loaded = true
        end

        @all
      end

      # Public: An array containing the keys of all the documents.
      #
      # Returns an array of symbols.
      def keys
        lookup_map.keys
      end

      # Public: Does a document with +key+ exist? Documents only "exist" when
      # saved; given a key for an unsaved document, false is returned.
      #
      # Returns true if a document exists, false otherwise.
      def key?(key)
        lookup_map.key?(key.to_sym)
      end

      # Public: A human-readable version of the Manager.
      #
      # Returns a string.
      def inspect
        relative = directory.relative_path_from(Atlas.data_dir)
        "#<#{ self.class.name } (#{ @klass.name } at ./#{ relative })>"
      end

      # Public: Returns the path to the documents for this manager.
      #
      # Returns a Pathname.
      # Raises a NoDirectorySetError if no path has been set.
      def directory
        Atlas.data_dir.join(directory_name) || raise(NoDirectorySetError, @klass.name)
      end

      # Internal: Sets the path where the documents for this manger are stored.
      #
      # This should be a relative path from the data directory root.
      #
      # Returns the given name.
      def directory_name=(name)
        clear!
        @directory_name = name
      end

      # Internal: Sets the file extension used by the documents.
      #
      # Returns the given name.
      def extension_name=(name)
        clear!
        @extension_name = name
      end

      # Internal: Writes a given document to disk.
      #
      # document - The document to be written.
      #
      # Returns true or false.
      def write(document)
        if key?(document.key) && get(document.key) != document
          fail Atlas::DuplicateKeyError.new(document.key)
        end

        path = document.path

        content = Atlas::HashToTextParser.new(
          serializable_attributes(document)
        ).to_text

        # Ensure the directory exists.
        FileUtils.mkdir_p(path.dirname)

        @all.push(document) unless path.file?

        path.open('w') do |file|
          file.write(content)
          file.write("\n") unless content[-1] == "\n"
        end

        lookup_map[document.key] = path
        @documents[document.key] = document

        true
      end

      # Internal: Given a path, removes the file from the disk, and the
      # associated document from the manager.
      #
      # Returns nothing.
      def delete_path(path)
        old_key = key_from_path(path)

        @all.delete(get(old_key))

        path.delete

        lookup_map.delete(old_key)
        @documents.delete(old_key)
      end

      # Internal: Clears the manager's internal cache when the data directory
      # is changed.
      #
      # Returns nothing.
      def clear!
        @documents  = {}
        @attributes = {}
        @lookup_map = nil
        @all_loaded = false
        @all        = []
      end

      # Internal: When a new manager is created, it is registered with the
      # Manager class so that its internal caches can be expired if the user
      # changes the data directory.
      #
      # manager - The Manager instance to be registered.
      #
      # Returns the manager.
      def self.register(manager)
        @managers ||= Set.new
        @managers.add(manager)
      end

      # Internal: Instructs all the registered managers to clear their
      # internal caches.
      #
      # Returns nothing.
      def self.clear_all!
        @managers.each(&:clear!) if @managers
        nil
      end

      private

      # Internal: A hash connecting the document keys with the path to the
      # file.
      #
      # Returns an array of Symbol keys and Pathname values.
      def lookup_map
        @lookup_map ||= begin
          gpath = directory.join("**/*.#{extension_name}")

          Pathname.glob(gpath).each_with_object({}) do |path, map|
            map[ key_from_path(path) ] = path
          end
        end
      end

      # Internal: A hash of attributes and values which can be persisted.
      #
      # Returns a Hash.
      def serializable_attributes(document)
        Atlas::Util.serializable_attributes(document.attributes.merge(
          comments: document.comments, queries: document.queries
        ))
      end

      # Internal: Loads a document from disk by its +key+.
      #
      # Returns the ActiveDocument.
      def load(key)
        (path = lookup_map[key]) || return

        # This is ugly, but significantly faster than relative_path_from and we
        # know that the path is prefixed exactly with the directory path.
        relative_path = path.to_s.delete_prefix("#{directory}/")

        basename =
          if (dir_index = relative_path.rindex('/'))
            relative_path[dir_index..-1]
          else
            relative_path
          end

        without_ext = basename.delete_suffix(".#{extension_name}")

        if without_ext.include?('.')
          subclass = without_ext.split('.').last

          begin
            klass = "#{ @klass.name }::#{ subclass.camelize }".constantize
          rescue NameError => ex
            fail Atlas::NoSuchDocumentClassError.new(subclass, relative_path)
          end
        else
          klass = @klass
        end

        attributes = load_attributes(path, key).merge!(path: relative_path)

        klass.new(attributes).tap do |doc|
          doc.manager = self
        end
      rescue ParserError => ex
        ex.path = path
        raise ex
      end

      # Internal: Given a document path or key, retrieves the attributes for
      # the document
      #
      # path - Path to the document file.
      # key  - The unique key which identifies the document.
      #
      # Returns a hash.
      def load_attributes(path, key)
        Atlas::Parser::TextToHash::Base.new(path.read).to_hash
      rescue Atlas::ParserError => ex
        ex.path = path
        fail ex
      end

      # Internal: Given a path, returns the key of the document.
      #
      # Returns a Symbol.
      def key_from_path(path)
        path.basename.to_s.split('.', 2).first.to_sym
      end
    end
  end
end
