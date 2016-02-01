module Atlas
  class MeritOrderDetails
    include ValueObject

    values do
      attribute :type,           Symbol
      attribute :group,          Symbol
      attribute :target,         Symbol
      attribute :demand_source,  Symbol
      attribute :demand_profile, Symbol
    end
  end # MeritOrderDetails
end # Atlas
