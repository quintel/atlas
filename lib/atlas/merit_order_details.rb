module Atlas
  class MeritOrderDetails
    include Virtus::ValueObject

    attribute :type,  Symbol
    attribute :group, Symbol
  end # MeritOrderDetails
end # Atlas
