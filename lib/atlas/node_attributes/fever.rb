# frozen_string_literal: true

module Atlas
  module NodeAttributes
    # Describes optional information for setting up the node within a Fever
    # calculation.
    class Fever
      include ValueObject
      include ActiveModel::Validations

      attr_accessor :share_in_group

      values do
        attribute :type,      Symbol
        attribute :group,     Symbol
        attribute :curve,     Hash[Symbol => Float]
        attribute :share_in_group, Float
        attribute :present_share_in_demand, Float

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

      validates :type, inclusion: %i[consumer producer]

      validates_presence_of :share_in_group,
        if: ->(mod) { mod.type == :producer },
        message: 'must be set for producers'

      validates_presence_of :technology_curve_type,
        if: ->(mod) { mod.type == :producer },
        message: 'must be set for producers'

      validates :technology_curve_type,
        inclusion: { in: ->(mod) { mod.class.technology_types } }

      validates_presence_of :curve,
        if: ->(mod) { mod.type == :consumer },
        message: 'must be set for consumers'

      validate :validate_curve_types

      def to_hash
        hash = super
        hash.delete(:capacity) if hash[:capacity].empty?

        hash
      end

      def self.technology_types
        @technology_types ||= %i[tech_day_night tech_constant].freeze
      end

      def validate_curve_types
        return unless type == :consumer

        unless curve.is_a?(Hash)
          errors.add(
            :curve,
            'must consist of a definition for each technology curve type, e.g. curve.tech_day_night'
          )
          return
        end

        if curve.keys.any? { |key| !Fever.technology_types.include?(key) }
          errors.add(:curve, "keys must be one of #{Fever.technology_types}")
        end
      end
    end
  end
end
