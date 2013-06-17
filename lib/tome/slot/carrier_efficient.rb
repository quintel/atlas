module Tome
  class Slot
    # Calculates the share of an output slot dynamically, according to the
    # share of inputs to the node, and efficiencies provided by the user.
    #
    # For example, take the following document:
    #
    #     # Coal accounts for 40% of input.
    #     - input.coal    = 0.4
    #
    #     # Biomass if 60% of input.
    #     - input.biomass = 0.6
    #
    #     # The electricity node has an efficiency of 50% when provided purely
    #     # coal as input...
    #     - output.electricity.coal = 0.5
    #
    #     # ... and an efficiency of 40% if provided purely biomass.
    #     - output.electricity.biomass = 0.4
    #
    # The share of the "electricity" slot in this case is 0.44 (or 44%). This
    # comes from 0.4 coal input at 0.5 efficiency, and 0.6 biomass input at
    # 0.4 efficiency).
    class CarrierEfficient < Slot
      # Public: The share of energy which leaves the node through this slot.
      # Calculated dynamically according to the share the inputs.
      #
      # Returns a numeric.
      def share
        node.in_slots.map do |slot|
          slot.share * node.output[carrier][slot.carrier]
        end.sum
      end
    end # CarrierEfficient
  end # Slot
end # Tome
