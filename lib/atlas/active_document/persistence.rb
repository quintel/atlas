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
        filename = [key, self.class.subclass_suffix, self.class::FILE_SUFFIX]
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

        if @last_saved_file_path != path && @last_saved_file_path.file?
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

      #######
      private
      #######

      # Internal: The thing.
      def manager
        @manager || self.class.manager
      end

      # ----------------------------------------------------------------------

      module ClassMethods
        # Public: The absolute path to the directory in which the documents
        # are stored.
        #
        # Returns a Pathname.
        def directory
          manager.directory
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
      end # ClassMethods

    end # Persistence
  end # ActiveDocument
end # Atlas
