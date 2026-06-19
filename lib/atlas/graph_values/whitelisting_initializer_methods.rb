module Atlas
  class GraphValues
    class WhitelistingInitializerMethods < ActiveModel::Validator

      def validate(record)
        return if (record.errors.messages[:values] || []).any?

        record.values.each_pair do |element, methods|
          graph_type, graph_element = find_element_and_type(element)

          methods.keys.each do |method|
            unless graph_element.graph_methods.include?(method)
              record.errors.add(:values,
                "#{ graph_type } '#{ element }' is not allowed to be edited by '#{ method }'")
            end
          end
        end
      end

      private

      # A graph key can be an edge or a node (with or without a slot carrier).
      #
      # An edge contains a dash (-) followed by an (@)
      # A node is a key
      #
      def find_element_and_type(graph_key)
        if graph_key =~ /-.+@/
          [:edge, find_edge(graph_key)]
        else
          [:node, find_node(graph_key)]
        end
      end

      def find_edge(graph_key)
        EnergyEdge.find(graph_key)
      rescue Atlas::DocumentNotFoundError
        MoleculeEdge.find(graph_key)
      end

      def find_node(graph_key)
        EnergyNode.find(graph_key)
      rescue Atlas::DocumentNotFoundError
        MoleculeNode.find(graph_key)
      end
    end
  end
end
