# frozen_string_literal: true

module Atlas
  class Runner
    # Molecule nodes at the far left or right of the graph, without an explicit demand assigned,
    # are defaulted to zero.
    ZeroMoleculeLeaves = lambda do |graph|
      graph.nodes.each do |node|
        next unless node.get(:model).graph_config == GraphConfig.molecules
        next unless node.edges(:in).none? || node.edges(:out).none?

        node.set(:demand, 0.0) unless node.demand
      end

      graph
    end
  end
end
