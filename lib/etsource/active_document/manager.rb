module ETSource
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
        lookup_map.keys.map { |key| get(key) }
      end

      # Public: A human-readable version of the Manager.
      #
      # Returns a string.
      def inspect
        relative = @klass.directory.relative_path_from(ETSource.data_dir)
        "#<#{ self.class.name } (#{ @klass.name } at ./#{ relative })>"
      end

      # Internal: Writes a given document to disk.
      #
      # document - The document to be written.
      #
      # Returns true or false.
      def write(document)
        path    = document.path
        content = ETSource::HashToTextParser.new(document.to_hash).to_text

        # Ensure the directory exists.
        FileUtils.mkdir_p(path.dirname)

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
        path.delete

        old_key = key_from_path(path)

        lookup_map.delete(old_key)
        @documents.delete(old_key)
      end

      # Internal: Clears the manager's internal cache when the ETSource data
      # directory is changed.
      #
      # Returns nothing.
      def clear!
        @documents  = {}
        @lookup_map = nil
      end

      # Internal: When a new manager is created, it is registered with the
      # Manager class so that its internal caches can be expired if the user
      # changes the ETSource data directory.
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

      #######
      private
      #######

      # Internal: A hash connecting the document keys with the path to the
      # file.
      #
      # Returns an array of Symbol keys and Pathname values.
      def lookup_map
        @lookup_map ||= begin
          gpath = @klass.directory.join("**/*.#{ @klass::FILE_SUFFIX }")

          Pathname.glob(gpath).each_with_object({}) do |path, map|
            map[ key_from_path(path) ] = path
          end
        end
      end

      # Internal: Loads a document from disk by its +key+.
      #
      # Returns the ActiveDocument.
      def load(key)
        return nil unless path = lookup_map[key]

        parsed_content = ETSource::TextToHashParser.new(path.read).to_hash
        relative_path  = path.relative_path_from(@klass.directory)
        without_ext    = relative_path.basename.sub_ext('')

        if without_ext.to_s.include?('.')
          subclass = without_ext.to_s.split('.').last
          klass = "ETSource::#{subclass.to_s.classify}".constantize
        else
          klass = @klass
        end

        klass.new(parsed_content.merge(path: relative_path.to_s))
      end

      # Internal: Given a path, returns the key of the document.
      #
      # Returns a Symbol.
      def key_from_path(path)
        path.basename.to_s.split('.', 2).first.to_sym
      end
    end # Manager
  end # IO
end # ETSource