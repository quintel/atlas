# frozen_string_literal: true

module Atlas
  class Runner
    # Iterates through each node in the graph, when it finds a fever producer
    # temporarily disables all nodes to the left from being calculated by Refinery
    PauseFeverCalculations = lambda do |refinery|
      refinery.nodes.each do |node|
        model = node.get(:model)
        next unless model.respond_to?(:fever) && model.fever&.type == :producer

        # If the node has an aggregator node to the left of it, that is the last node that
        # should be calculated
        pause_from_node =
          if model.groups.include?(:aggregator_producer)
            node.out_edges.first.to
          else
            node
          end

        pause_from_node.out_edges.each(&:wait!)

        pause_from_node.descendants.each do |descendant|
          descendant.wait!
          descendant.out_edges.each(&:wait!)
        end
      end

      refinery
    end
  end
end
