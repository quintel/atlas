# frozen_string_literal: true

module Atlas
  class EnergyNode
    # A Demand Node tracks the demand for a certain purpose. It needs to have a 'preset_demand' in
    # order to be calculated by Refinery
    class Demand < EnergyNode
    end
  end
end
