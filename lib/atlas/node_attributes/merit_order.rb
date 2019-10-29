# frozen_string_literal: true

module Atlas
  module NodeAttributes
    class MeritOrder
      include ValueObject
      include ActiveModel::Validations

      values do
        attribute :type,           Symbol
        attribute :subtype,        Symbol, default: :generic
        attribute :group,          Symbol
        attribute :level,          Symbol, default: :hv
        attribute :delegate,       Symbol
        attribute :demand_source,  Symbol
        attribute :demand_profile, Symbol
      end

      validates :type, inclusion: %i[consumer flex producer]
      validates :level, inclusion: %i[lv mv hv omit]

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
    end
  end
end
