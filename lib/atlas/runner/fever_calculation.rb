# frozen_string_literal: true

module Atlas
  class Runner
    # Iterates through each node in the graph, when it finds a fever producer, starts
    # the sorting algorithm and
    # enables all nodes to the left from being calculated in refinery
    module FeverCalculation
      ConsumerCalculator = Struct.new(:consumer, :total_demand, :unfilled_demand)

      # TODO: refactor and add comments
      def self.with_dataset(dataset)
        lambda do |refinery|
          groups = refinery.nodes.select { |n| fever_node?(n) }.group_by do |node|
            node.get(:model).fever.group
          end

          groups.each do |_, group|
            # Algorithm per group can go to submodule
            # TODO: ORDER THEM HERE!!
            producers = group.select { |node| node.get(:model).fever.type == :producer }

            group_demand = producers.sum do |node|
              node_connected_to_consumer(node).demand
            end

            # TODO: ORDER THEM HERE!!
            consumers = group
              .select { |node| node.get(:model).fever.type == :consumer }
              .map do |cons|
                # TODO: this '2' should be the share of consumer from area attribute (dataset)
                demand = Rational(group_demand / 2)
                ConsumerCalculator.new(cons, demand, demand)
              end

            total_nou = consumers.sum { |cons| cons.consumer.get(:model).number_of_units }

            producers.each do |producer|
              producer_for_demand = node_connected_to_consumer(producer)
              demand = producer_for_demand.demand
              supplying_nou = 0.0

              consumers.each do |consumer|
                break unless demand.positive? # nee want wellicht de rest op 0? CHECK!
                next unless consumer.unfilled_demand.positive?

                edge_to_consumer = producer_for_demand
                  .out_edges
                  .detect { |e| e.to == consumer.consumer }

                next unless edge_to_consumer

                energy = [demand, consumer.unfilled_demand].min

                share_to_consumer = Rational(energy / producer_for_demand.demand)
                share_from_consumer = Rational(energy / consumer.total_demand)

                supplying_nou += share_from_consumer * consumer.consumer.get(:model).number_of_units
                consumer.unfilled_demand -= energy
                demand -= energy

                edge_to_consumer.set(:parent_share, share_to_consumer)
              end

              producer.get(:model).fever.share_in_group = supplying_nou / total_nou
              enable_calculations_after(producer)
            end
          end

          refinery
        end
      end

      def self.fever_node?(node)
        model = node.get(:model)
        model.respond_to?(:fever) && model.fever
      end

      def self.node_connected_to_consumer(producer_node)
        model = producer_node.get(:model)
        if model.groups.include?(:aggregator_producer)
          producer_node.out_edges.first.to
        else
          producer_node
        end
      end

      def self.enable_calculations_after(node)
        node.out_edges.each(&:continue!)

        node.descendants.each do |descendant|
          descendant.continue!
          descendant.out_edges.each(&:continue!)
        end
      end
    end
  end
end
