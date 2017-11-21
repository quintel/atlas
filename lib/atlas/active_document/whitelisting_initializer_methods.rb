module Atlas
  module ActiveDocument
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
      # A node can be just a key or can be in the format of a slot:
      #
      #  a@b (the @b needs to be removed from the key in order to be correctly
      #       validated)
      #
      # Therefor, we'll allow any slot to be edited from every node.
      #
      def find_element_and_type(graph_key)
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
