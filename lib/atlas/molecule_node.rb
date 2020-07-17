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

    # Public: The queries to be executed and saved on the Refinery graph.
    #
    # Defaults demand to zero, as the molecule graph should have no flows.
    #
    # Returns a Hash.
    def queries
      { demand: '0.0' }.merge(super)
    end
  end
end
