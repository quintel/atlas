module Atlas
  # Describes optional information for setting up the node within a Fever
  # calculation.
  class FeverDetails
    include ValueObject

    values do
      attribute :type,      Symbol
      attribute :group,     Symbol
      attribute :curve,     Symbol,  default: nil
      attribute :defer_for, Integer, default: 0
    end
  end
end
