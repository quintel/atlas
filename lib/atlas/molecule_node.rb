# frozen_string_literal: true

require_relative 'node'

module Atlas
  # Describes a Node in the molecules graph.
  class MoleculeNode
    include Node

    directory_name 'graphs/molecules/nodes'

    def self.graph_config
      GraphConfig.molecules
    end

    attribute :from_energy, NodeAttributes::EnergyToMolecules

    # Molecule nodes define output capacity; the capacity of all non-loss output carriers.
    attribute :output_capacity, Float

    validates_with Atlas::ActiveDocument::AssociatedValidator, attribute: :from_energy
  end
end
