# frozen_string_literal: true

module Atlas
  module NodeAttributes
    # Describes optional information for setting up the node within a Fever
    # calculation.
    class Fever
      include ValueObject

      values do
        attribute :type,      Symbol
        attribute :group,     Symbol
        attribute :curve,     Hash[Symbol => Float]
        attribute :share_in_group, Float

        # Which of the technology curves to use for producers
        attribute :technology_curve_type, Symbol

        # Deferrable demands.
        attribute :defer_for, Integer

        # Variable efficiency.
        attribute :efficiency_based_on,      Symbol
        attribute :efficiency_balanced_with, Symbol

        # The base coefficient of performance, and the COP change per degree of
        # ambient temperature.
        attribute :base_cop,       Float
        attribute :cop_per_degree, Float
        attribute :cop_cutoff,     Float

        # Use a producer defined on another node.
        attribute :alias_of, Symbol

        # Custom capacities for producers which have multiple components.
        attribute :capacity, Hash[Symbol => Float]
      end

      def to_hash
        hash = super
        hash.delete(:capacity) if hash[:capacity].empty?

        hash
      end
    end
  end
end
