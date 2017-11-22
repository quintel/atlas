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
          set_graph_methods(dataset, node)

          (node.slots.in.to_a + node.slots.out.to_a).each do |slot|
            set_graph_methods_to_slot!(dataset, node, slot)
          end

          node.out_edges.each do |edge|
            set_graph_methods(dataset, edge)
          end
        end
      end

      # Private: set_graph_methods
      #
      # el = Atlas element either a Slot, Edge or Node
      # dataset = an Atlas::Datset::Derived
      def self.set_graph_methods(dataset, refinery_element, atlas_element = nil)
        atlas_element = atlas_element || refinery_element.get(:model)

        (dataset.graph_values.for(atlas_element) || {})
          .each_pair do |method, val|
            refinery_element.set(method.to_sym, val)
          end
      end

      def self.set_graph_methods_to_slot!(dataset, node, slot)
        atlas_slot = Atlas::Slot.slot_for(
          node.get(:model),
          slot.direction,
          slot.carrier
        )

        set_graph_methods(dataset, slot, atlas_slot)
      end
    end
  end
end
