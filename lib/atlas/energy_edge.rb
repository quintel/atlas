# frozen_string_literal: true

require_relative 'edge'

module Atlas
  # An edge within the energy graph. See Edge.
  class EnergyEdge
    # require 'pry'
    # binding.pry

    include Edge

    directory_name 'graphs/energy/edges'

    def self.node_class
      EnergyNode
    end
  end
end
