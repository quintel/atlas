# frozen_string_literal: true

module Atlas
  # Contains configuration settings for each graph computed by Atlas and Refinery.
  module GraphConfig
    Config = Struct.new(:name, :edge_class, :node_class)

    module_function

    def energy
      @energy ||= Config.new(:energy, EnergyEdge, EnergyNode)
    end

    def molecules
      @molecules ||= Config.new(:molecules, MoleculeEdge, MoleculeNode)
    end
  end
end
