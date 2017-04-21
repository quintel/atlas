module Atlas
  class MeritOrderDetails
    include ValueObject

    values do
      attribute :type,           Symbol
      attribute :group,          Symbol
      attribute :target,         Symbol
      attribute :demand_source,  Symbol
      attribute :demand_profile, Symbol
      attribute :profile_mix,    Hash[Symbol => Float], default: nil
    end

    def to_hash
      super.delete_if { |_, value| value.nil? }
    end
  end # MeritOrderDetails
end # Atlas
