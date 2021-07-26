# frozen_string_literal: true

module Atlas
  module NodeAttributes
    # Contains attributes allowing the node to participate in a merit order
    # calculation in ETEngine.
    class MeritOrder
      include ValueObject
      include ActiveModel::Validations

      values do
        attribute :type,    Symbol
        attribute :subtype, Symbol, default: :generic
        attribute :group,   Symbol

        attribute :output_capacity_from_demand_of, Symbol
        attribute :output_capacity_from_demand_share, Float
      end

      validates :type, inclusion: %i[consumer flex producer]

      # Producer subtypes.
      validates :subtype,
        inclusion: %i[dispatchable must_run volatile],
        if: ->(mod) { mod.type == :producer }

      # Consumer subtypes.
      validates :subtype,
        inclusion: %i[generic pseudo],
        if: ->(mod) { mod.type == :consumer }

      validates_absence_of :output_capacity_from_demand_of,
        unless: ->(mod) { mod.subtype == :storage },
        message: 'must be blank when subtype is not storage'

      validates_absence_of :output_capacity_from_demand_share,
        unless: ->(mod) { mod.subtype == :storage },
        message: 'must be blank when subtype is not storage'

      def delegate
        super if self.class.attribute_set[:delegate]
      end

      # Electricity merit order attribute: unused in other Merit calculations.
      def production_curtailment; end
    end
  end
end
