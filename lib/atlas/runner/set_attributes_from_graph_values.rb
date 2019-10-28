# frozen_string_literal: true

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
        atlas_element ||= refinery_element.get(:model)

        (dataset.graph_values.for(atlas_element) || {})
          .each_pair do |method, val|
            case method
            when 'input', 'output'
              set_graph_methods_to_slot!(refinery_element, method, val)
            else
              refinery_element.set(method.to_sym, val)
            end
          end
      end

      def self.set_graph_methods_to_slot!(node, method, values)
        values.each_pair do |carrier, share|
          node.slots
            .public_send(method.sub(/put/, ''), carrier.to_sym)
            .set(:share, share)
        end
      end
    end
  end
end
