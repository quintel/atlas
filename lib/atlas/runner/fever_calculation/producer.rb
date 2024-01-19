# frozen_string_literal: true

module Atlas
  class Runner
    module FeverCalculation
      # Wraps around a Fever producer refinery node and provides methods needed for calculation
      class Producer
        attr_accessor :number_of_units
        # How much space (energy) the producer has left to supply to consumers
        attr_accessor :space

        def initialize(node)
          @node = node
          @number_of_units = 0.0
          @space = demand
        end

        def demand
          @demand ||= node_for_demand.demand
        end

        # Public: Returns the edge connected to the Consumer, if no edge then nil
        def edge_to(consumer)
          node_for_demand.out_edges.detect { |e| e.to == consumer.consumer }
        end

        # Public: sets the producer nodes fever.share_in_group based on the total
        # number of units in the group. This is needed for the future graph, queries and inputs
        def set_share_in_group(total_number_of_units)
          @node.get(:model).fever.share_in_group = share_in_group(total_number_of_units)
        end

        # Public: Unpauses the calculations for Refinery. If Renfiney encounters these
        # nodes and edges now, it will calculate all demands
        def unpause_refinery_calculations
          @node.out_edges.each(&:continue!)

          @node.descendants.each do |descendant|
            descendant.continue!
            descendant.out_edges.each(&:continue!)
          end
        end

        private

        # Private: These fever producer nodes often have an aggregator node to the left
        # that is connected to the consumer, instead of the producer node being directly
        # connected to the consumer.
        # If so, that is the node that should be used for calculation
        def node_for_demand
          @node_for_demand ||= find_node_for_demand
        end

        def find_node_for_demand
          model = @node.get(:model)
          if model.groups.include?(:aggregator_producer)
            @node.out_edges.first.to
          else
            @node
          end
        end

        # Private: calculate the share of the producer in the group based on  number of units
        def share_in_group(total_number_of_units)
          total_number_of_units.positive? ? number_of_units / total_number_of_units : 0.0
        end
      end
    end
  end
end
