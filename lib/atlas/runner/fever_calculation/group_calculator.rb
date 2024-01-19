# frozen_string_literal: true

module Atlas
  class Runner
    module FeverCalculation
      # Calculates fever edges parent_shares between consumers and producers per fever group
      # based on a simple algorithm between ordered producers and consumers.
      # Also sets the `fever.share_in_group` attribute on producers, neccesary for inputs and
      # queries and future graph calculations
      class GroupCalculator
        Consumer = Struct.new(:consumer, :total_demand, :unfilled_demand)

        def self.calculate(*args)
          new(*args).calculate
        end

        def initialize(group, name, query)
          @group = group
          @name = name
          @query = query
        end

        # Public: Set the parent shares for each of the ordered producers towards
        # the ordered consumers, and sets the share_in_group fever attribute for producers
        # enables the continuation of renifery calculations after the producer has been 'calculated'
        def calculate
          producers.each do |producer|
            consumers.each do |consumer|
              # Check if this consumer is actually connected to the producer
              edge_to_consumer = producer.edge_to(consumer)
              next unless edge_to_consumer

              # Check if the consumer still has unfilled demand and if
              # the producer has energy left to divide
              unless consumer.unfilled_demand.positive? && producer.space.positive?
                edge_to_consumer.set(:parent_share, 0.0)
                next
              end

              # How much energy can the producer supply to the consumer
              energy = [producer.space, consumer.unfilled_demand].min

              consumer.unfilled_demand -= energy
              producer.space -= energy

              # Add the number of units the producer is supplying to for this consumer node
              producer.number_of_units += Rational(energy / consumer.total_demand) *
                query_attribute(consumer.consumer, :number_of_units)

              # Only set the parent share on the edge from the (aggregated) producer to the
              # consumer. Refinery will calculate the rest in a later stage
              edge_to_consumer.set(:parent_share, Rational(energy / producer.demand))
            end

            # Based on the number of units the producer is supplying to, its fever.share_in_group
            # can be calculated. This is needed for the future graph, queries and inputs
            producer.set_share_in_group(number_of_units)

            producer.unpause_refinery_calculations
          end
        end

        private

        # Private: All producer nodes in the group, ordered and wrapped in Producer objects
        def producers
          @producers ||= @group
            .select { |node| node.get(:model).fever.type == :producer }
            .sort_by { |node| producer_order.index(node.key.to_s) || producer_order.length }
            .map { |node| Producer.new(node) }
        end

        # Private: All consumers in the group, ordered and wrapped in Consumer objects
        def consumers
          @consumers ||= @group
            .select { |node| node.get(:model).fever.type == :consumer }
            .sort_by { |node| consumer_order.index(node.key.to_s) || consumer_order.length }
            .map do |node|
              demand = Rational(
                group_demand * query_attribute(node, :'fever.present_share_in_demand')
              )
              Consumer.new(node, demand, demand)
            end
        end

        def producer_order
          Atlas::Config.read("fever.#{@name}_producer_order")
        end

        def consumer_order
          Atlas::Config.read("fever.#{@name}_consumer_order")
        end

        # Private: Calculate the total demand that has to be supplied to the consumers
        def group_demand
          @group_demand ||= producers.sum(&:demand)
        end

        # Private: Calculate the total number of units the producers should supply to
        def number_of_units
          @number_of_units ||= consumers.sum do |consumer|
            query_attribute(consumer.consumer, :number_of_units)
          end
        end

        # Private: Helper to either get the attribute directly on the node or via query
        def query_attribute(node, attribute)
          if node.get(:model).queries.key?(attribute)
            return @query.call(node.get(:model).queries[attribute])
          end

          if attribute.start_with?('fever')
            node.get(:model).fever.public_send(attribute.to_s.split('.').last.to_sym) || 0.0
          else
            node.get(:model).public_send(attribute) || 0.0
          end
        end
      end
    end
  end
end
