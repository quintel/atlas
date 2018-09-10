module Atlas
  class MeritOrderDetails
    include ValueObject
    include ActiveModel::Validations

    values do
      attribute :type,           Symbol
      attribute :group,          Symbol
      attribute :level,          Symbol, default: :hv
      attribute :delegate,       Symbol
      attribute :demand_source,  Symbol
      attribute :demand_profile, Symbol
    end

    validates :type, inclusion: %i[consumer dispatchable flex must_run volatile]
    validates :level, inclusion: %i[lv mv hv omit]
  end # MeritOrderDetails
end # Atlas
