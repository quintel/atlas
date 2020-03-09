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

      validates_inclusion_of :group,
        in: ->(_mod) { Array(Config.read?('flexibility_order')).map(&:to_sym) },
        if: ->(mod) { mod.type == :flex },
        message: 'is not a permitted flexibility order option'

      def delegate
        super if self.class.attribute_set[:delegate]
      end

      # Electricity merit order attribute: unused in other Merit calculations.
      def production_curtailment; end
    end
  end
end
