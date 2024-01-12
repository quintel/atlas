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

          groups.each do |name, group|
            # TODO: can't we do this in a more proper way? It will not change between datasets.
            producer_order = Atlas::Config.read("fever.#{name}_producer_order")
            consumer_order = Atlas::Config.read("fever.#{name}_consumer_order")

            # TODO: Algorithm per group can go to submodule

            # Take all the producers from the group and order them
            producers = group
              .select { |node| node.get(:model).fever.type == :producer }
              .sort_by do |node|
                producer_order.index(node.key.to_s) || producer_order.length
              end

            # Calculate the total demand that has to be supplied to the consumers
            group_demand = producers.sum do |node|
              node_connected_to_consumer(node).demand
            end

            # Take all the consumers from the group and order them
            consumers = group
              .select { |node| node.get(:model).fever.type == :consumer }
              .sort_by { |node| consumer_order.index(node.key.to_s) || consumer_order.length }
              .map do |cons|
                # TODO: this '2' should be the share of consumer from area attribute (dataset)
                demand = Rational(group_demand / 2)
                ConsumerCalculator.new(cons, demand, demand)
              end

            # Calculate the total number of units the producers should supply to
            total_nou = consumers.sum { |cons| cons.consumer.get(:model).number_of_units }

            # Set the parent shares for each of the ordered producers towards the ordered consumers
            producers.each do |producer|
              producer_for_demand = node_connected_to_consumer(producer)
              demand = producer_for_demand.demand
              supplying_nou = 0.0

              consumers.each do |consumer|
                # Continue until the producer has no more energy to divide
                break unless demand.positive? # nee want wellicht de rest op 0? CHECK!
                # Check if the consumer still has unfilled demand
                next unless consumer.unfilled_demand.positive?

                # Check if this consumer is actually connected to the producer
                edge_to_consumer = producer_for_demand
                  .out_edges
                  .detect { |e| e.to == consumer.consumer }

                next unless edge_to_consumer

                # How much energy can the producer supply to the consumer
                energy = [demand, consumer.unfilled_demand].min

                share_to_consumer = Rational(energy / producer_for_demand.demand)
                share_from_consumer = Rational(energy / consumer.total_demand)

                # Add the number of units the producer is supplying in this consumer node
                supplying_nou += share_from_consumer * consumer.consumer.get(:model).number_of_units

                consumer.unfilled_demand -= energy
                demand -= energy

                # Only set the parent share on the edge from the (aggregated) producer to the
                # consumer, Refinery will calculate the rest in a later stage
                edge_to_consumer.set(:parent_share, share_to_consumer)
              end

              # Based on the number of units the producer is supplying to, its fever.share_in_group
              # can be calculated. This is needed for the future graph, queries and inputs
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
