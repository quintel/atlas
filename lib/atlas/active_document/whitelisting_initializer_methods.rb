module Atlas
  module ActiveDocument
    class WhitelistingInitializerMethods < ActiveModel::Validator

      def validate(record)
        return if (record.errors.messages[:initializer_inputs] || []).any?

        record.initializer_inputs.each_pair do |key, elements|
          elements.each_key do |graph_key|
            graph_type, graph_element = find_element_and_type(graph_key, record)

            unless graph_element.initializer_inputs.include?(key)
              record.errors.add(:initializer_inputs,
                "#{ graph_type } '#{ graph_key }' is not allowed to be edited by '#{ key }'")
            end
          end
        end
      end

      private

      # A graph key can be an edge or a node (with or without a slot carrier).
      #
      # An edge contains a dash (-) followed by an (@)
      # A node can be just a key or can be in the format of a slot:
      #
      #  a@b (the @b needs to be removed from the key in order to be correctly
      #       validated)
      #
      # Therefor, we'll allow any slot to be edited from every node.
      #
      def find_element_and_type(graph_key, record)
        if graph_key =~ /-.+@/
          [:edge, Edge.find(graph_key)]
        elsif graph_key =~ /@.+/
          [:slot, Node.find(graph_key.to_s.sub(/@.+/, ''))]
        else
          [:node, Node.find(graph_key)]
        end
      end
    end
  end
end
