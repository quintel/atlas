# frozen_string_literal: true

require_relative 'edge'

module Atlas
  # An edge within the energy graph. See Edge.
  class EnergyEdge
    include Edge

    directory_name 'graphs/energy/edges'

    def self.graph_config
      GraphConfig.energy
    end
  end
end
