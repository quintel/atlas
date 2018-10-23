# frozen_string_literal: true

module Atlas
  class MeritOrderDetails
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
  end # MeritOrderDetails
end # Atlas
