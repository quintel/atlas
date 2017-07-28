module Atlas
  # Describes optional information for setting up the node within a Fever
  # calculation.
  class FeverDetails
    include ValueObject

    values do
      attribute :type,      Symbol
      attribute :group,     Symbol
      attribute :curve,     String

      # Deferrable demands.
      attribute :defer_for, Integer

      # Variable efficiency.
      attribute :efficiency_based_on,      Symbol
      attribute :efficiency_balanced_with, Symbol
    end
  end
end
