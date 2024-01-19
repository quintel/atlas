# frozen_string_literal: true

module Atlas
  class Runner
    # Iterates through each node in the graph, when it finds a fever producer, starts
    # the sorting algorithm and enables all nodes to the left from being calculated in refinery
    module FeverCalculation
      def self.with_queryable(query)
        lambda do |refinery|
          groups = refinery.nodes.select { |n| fever_node?(n) }.group_by do |node|
            node.get(:model).fever.group
          end

          groups.each do |name, group|
            GroupCalculator.calculate(group, name, query)
          end

          refinery
        end
      end

      def self.fever_node?(node)
        model = node.get(:model)
        model.respond_to?(:fever) && model.fever
      end
    end
  end
end
