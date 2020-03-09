# frozen_string_literal: true

require_relative './merit_order'

module Atlas
  module NodeAttributes
    # Contains information about the node's participation in the electricity
    # merit order calculation.
    class ElectricityMeritOrder < MeritOrder
      values do
        # Defines whether the node is an HV, MV, or LV component.
        attribute :level, Symbol, default: :hv

        # Used with power-to-heat to define a node which should be used as the
        # source of demand.
        attribute :demand_source, Symbol

        # Used with power-to-heat to defines the profile used to shape demand.
        attribute :demand_profile, Symbol

        # If this node acts on behalf of another in the Merit order, attributes
        # (such as capacity) will be taken from the named delegate instead of
        # this node.
        attribute :delegate, Symbol

        # Sets a percentage of production load to be curtailed. For example, if
        # this is set to 0.2, the top 20% of the profile will be removed.
        attribute :production_curtailment, Float
      end

      validates :level, inclusion: %i[lv mv hv omit]

      validates :production_curtailment, absence: true, if: (lambda do |mo|
        mo.type != :producer || !%i[must_run volatile].include?(mo.subtype)
      end)
    end
  end
end
