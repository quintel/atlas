module Atlas
  module ActiveDocument
    module Finders
      extend ActiveSupport::Concern

      module ClassMethods
        # Public: All the things!
        #
        # Returns an array containing all the documents.
        def all
          if superclass.ancestors.include?(ActiveDocument)
            manager.all.select { |model| model.is_a?(self) }
          else
            manager.all
          end
        end

        # Public: Given a document +key+ finds the matching document.
        #
        # key - The key whose document you want to retrieve.
        #
        # Returns an ActiveDocument, or nil if no such document exists.
        def find(key)
          document = manager.get(key)

          # Prevent finding a node which is a member of the superclass, but
          # not this subclass, e.g. FinalDemandNode.find('not_an_fd_node')
          if document.nil? || ! document.is_a?(self)
            fail(DocumentNotFoundError.new(key, self))
          end

          document
        end
      end # ClassMethods

    end # Finders
  end # ActiveDocument
end # Atlas
