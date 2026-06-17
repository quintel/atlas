# frozen_string_literal: true

module Atlas
  class Runner
    # Derived datasets have no moleule flows.
    ZeroMoleculeNodes = lambda do |graph|
      graph.nodes.each do |node|
        model = node.get(:model)
        next unless model.graph_config == GraphConfig.molecules
        next if model.scaling_exempt

        node.set(:demand, 0.0)
      end

      graph
    end
  end
end
