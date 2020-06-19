# frozen_string_literal: true

require_relative 'demand'

module Atlas
  class EnergyNode
    # A FinalDemand node must define a value or query for the `demand` attribute.
    class FinalDemand < Demand
      validates_with QueryValidator, attributes: [:demand]
    end
  end
end
