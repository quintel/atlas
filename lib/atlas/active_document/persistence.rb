module Atlas
  module ActiveDocument
    module Persistence
      extend ActiveSupport::Concern

      included do
        # Public: Many documents are stored in the root document path (e.g.
        # nodes/, edges/, however it is acceptable to also store them in
        # deeper subdirectories. This contains the subdirectory part of the
        # file's path.
        #
        # Returns a String.
        attr_reader :subdirectory
      end

      # Public: The absolute path to the document.
      #
      # Returns a Pathname.
      def path
        filename = [key, self.class.subclass_suffix, self.class.extension_name]
        filename = filename.compact.join('.')

        if subdirectory
          directory.join(subdirectory).join(filename)
        else
          directory.join(filename)
        end
      end

      # Public: Sets a new path for the document.
      #
      # You may:
      #
      #   * Provide an absolute path if the path is within the +directory+ for
      #     these documents.
      #   * Provide a non-absolute path, which will be relative to the
      #     document +directory+.
      #   * Omit the +subclass_suffix+ used to tell ActiveDocument which
      #     subclass to instantiate.
      #   * Omit the file extension.
      #
      # You may not:
      #
      #   * Change the file extension; new extensions will be ignored.
      #   * Change the +subclass_suffix+; new suffixes will be ignored.
      #
      # Returns the path you gave.
      def path=(path)
        path = Pathname.new(path)

        if path.absolute?
          relative = path.relative_path_from(directory)
        else
          relative = path
        end

        if relative.to_s.include?('..')
          fail IllegalDirectoryError.new(path, directory)
        end

        set_attributes_from_filename!(relative)
      end

      # Public: The absolute path to the directory in which the documents
      # are stored.
      #
      # Returns a Pathname.
      def directory
        self.class.directory
      end

      # Public: Updates the document's attributes with those given, and saves.
      #
      # attributes - Attributes to be updated on the document.
      #
      # Returns true, or raises an error if the save fails.
      def update_attributes!(attributes)
        self.attributes = attributes
        save!
      end

      # Public: Saves the document to a file on disk.
      #
      # validate - Whether to perform validation prior to saving.
      #            Defaults to true. Setting this to false will save
      #            the document even if the attributes are not valid.
      #
      # Returns true, or false if the validation failed.
      def save(validate = true)
        return false if validate && ! valid?

        if @last_saved_file_path != path && @last_saved_file_path&.file?
          manager.delete_path(@last_saved_file_path)
        end

        manager.write(self)
      end

      # Public: Saves the document to a file on disk.
      #
      # Returns true, or raises an error if the save fails.
      def save!
        fail(InvalidDocumentError.new(self)) unless save
        true
      end

      # Public: Returns true if this document is persisted - i.e. has been saved
      # to storage - otherwise returns false.
      def persisted?
        path.file? || @last_saved_file_path && @last_saved_file_path.file?
      end

      # Public: Returns true if this record has not yet been saved - i.e. has
      # not been saved to storage - otherwise returns false.
      def new_record?
        !persisted?
      end

      # Public: Removes the document from the disk, effectively deleting the
      # record.
      #
      # Returns nothing.
      def destroy!
        manager.delete(self)
      end

      def manager=(manager)
        if @manager
          fail AtlasError, "You may not change a document's manager"
        end

        @manager = manager
      end

      private

      # Internal: The thing.
      def manager
        @manager || self.class.manager
      end

      # --------------------------------------------------------------------------------------------

      module ClassMethods
        # Public: The absolute path to the directory in which the documents
        # are stored.
        #
        # Returns a Pathname.
        def directory
          manager.directory
        end

        # Public: Sets the name of the directory (relative to the data_dir) in which the .ad files
        # for this class are stored. If no name is provided, the current name is returned.
        #
        # Directory names may only be set on top-most document classes; attempts to set the name on
        # a subclass will raise NotTopmostClassError.
        #
        # name - The directory name as a string. May include "/" to specify subdirectories.
        #
        # Returns the name.
        def directory_name(name = nil)
          raise(NotTopmostClassError, :directory_name) if name && subclassed_document?

          manager.directory_name = name if name
          manager.directory_name
        end

        # Public: Sets the extension name of files loaded by the ActiveDocumetn class. If no name is
        # provided, the current name is returned.
        #
        # Extension names may only be set on top-most document classes; attempts to set the name on
        # a subclass will raise NotTopmostClassError.
        #
        # name - The extension name as a string, without a leading ".".
        #
        # Returns the name.
        def extension_name(name = nil)
          raise(NotTopmostClassError, :extension_name) if name && subclassed_document?

          manager.extension_name = name if name
          manager.extension_name
        end

        # Internal: The Manager used to fetch the documents from disk.
        #
        # Returns an Atlas::ActiveDocument::Manager.
        def manager
          if subclassed_document?
            topmost_document_class.manager
          else
            @manager ||= Manager.new(self)
          end
        end

        # Public: Given attributes for a document, creates and saves the
        # document. The document is not saved if there are validation errors.
        #
        # attributes - Attributes to be set on the document.
        #
        # Returns the document instance.
        def create(attributes)
          new(attributes).tap(&:save)
        end

        # Public: Given attributes for a document, creates and saves the
        # document. An exception is raised if there are validation failures.
        #
        # attributes - Attributes to be set on the document.
        #
        # Returns the document instance.
        def create!(attributes)
          new(attributes).tap(&:save!)
        end
      end

    end
  end
end
