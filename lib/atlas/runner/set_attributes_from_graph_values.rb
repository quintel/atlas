module Atlas
  class Runner
    module SetAttributesFromGraphValues
      def self.with_dataset(dataset)
        lambda do |refinery|
          apply_graph_methods!(refinery, dataset)

          refinery
        end
      end

      private

      def self.apply_graph_methods!(refinery, dataset)
        refinery.nodes.each do |node|
          set_graph_methods(node, dataset)

          (node.slots.in.to_a + node.slots.out.to_a).each do |slot|
            set_graph_methods_to_slot!(node, slot, dataset)
          end

          node.out_edges.each do |edge|
            set_graph_methods(edge, dataset)
          end
        end
      end

      def self.set_graph_methods(element, dataset)
        el = element.get(:model)

        el.graph_methods.each do |method|
          if values = dataset.graph_values.values[el.key.to_s]
            values.each_pair do |method, value|
              attr = case method
                     when 'demand'          then :demand
                     when 'share'           then :share
                     when 'number_of_units' then :number_of_units
                     end

              element.set(attr, value)
            end
          end
        end
      end

      def self.set_graph_methods_to_slot!(node, slot, dataset)
        direction        = slot.direction == :in ? '+' : '-'
        graph_method_key = "#{ node.key }@#{ direction }#{ slot.carrier }"

        if graph_value = dataset.graph_values.values[graph_method_key]
          slot.set(:share, graph_value['share'])
        end
      end
    end
  end
end
