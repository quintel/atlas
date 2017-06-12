module Atlas
  class MeritOrderDetails
    include ValueObject

    values do
      attribute :type,   Symbol
      attribute :group,  Symbol
      attribute :target, Symbol
    end
  end # MeritOrderDetails
end # Atlas
