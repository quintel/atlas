module Atlas
  class Runner
    module SetAttributesFromGraphValues
      def self.with_dataset(dataset)
        lambda do |refinery|
          apply_graph_methods!(refinery, dataset)
          apply_slots!(refinery, dataset)

          refinery
        end
      end

      private

      def self.apply_graph_methods!(refinery, dataset)
        refinery.nodes.each do |node|
          set_graph_methods(node, dataset)

          node.out_edges.each do |edge|
            set_graph_methods(edge, dataset)
          end
        end
      end

      def self.set_graph_methods(element, dataset)
        el = element.get(:model)

        el.graph_methods.each do |method|
          values = dataset.graph_values[method] || {}
          value  = values[el.key.to_s]

          if value
            attr = case method
                   when 'demand'          then :demand
                   when 'share'           then :share
                   when 'number_of_units' then :number_of_units
                   end

            element.set(attr, value)
          end
        end
      end

      def self.apply_slots!(refinery, dataset)
        (dataset.graph_values['conversion'] || {}).each_pair do |key, value|
          node_name, carrier = key.to_s.split(/@[-+]/)
          slots = refinery.node(node_name.to_sym).slots

          slot = case key
                 when /\+/ then slots.in(carrier.to_sym)
                 when /\-/ then slots.out(carrier.to_sym)
                 else
                   raise ArgumentError, "missing + or -"
                 end

          slot.set(:share, value)
        end
      end
    end
  end
end
