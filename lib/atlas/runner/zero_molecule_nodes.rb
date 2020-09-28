# frozen_string_literal: true

module Atlas
  class Runner
    # Derived datasets have no moleule flows.
    ZeroMoleculeNodes = lambda do |graph|
      graph.nodes.each do |node|
        next unless node.get(:model).graph_config == GraphConfig.molecules

        node.set(:demand, 0.0)
      end

      graph
    end
  end
end
