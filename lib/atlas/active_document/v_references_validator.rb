module Atlas
  module ActiveDocument
    # Asserts that V refererencing a node exists
    class VReferencesValidator
      def validate(record)
        return unless contains_v

        referenced_nodes.each do |node|
          DocumentReferenceValidator.validate(
            record,
            attribute: node,
            class_name: 'node'
          )
        end
      end

      private

      def contains_v
        # zit er een V in /V\((.*?)\)/
      end

      # Returns an Array of node names
      def referenced_nodes
        # Pak alles in de V
        # /V\((.*?)\)/
        # Haal de groepen eruit
        # return de nodes
      end
    end
  end
end
