# frozen_string_literal: true

require_relative './merit_order'

module Atlas
  module NodeAttributes
    # Contains information about the node's participation in the electricity
    # merit order calculation.
    class ElectricityMeritOrder < MeritOrder
      values do
        # Defines whether the node is an HV, MV, or LV component.
        attribute :level, Symbol, default: :hv

        # Used with power-to-heat to define a node which should be used as the
        # source of demand. Also used with load shifting demand reduction,
        # where the demand source may be an array containing multiple nodes.
        attribute :demand_source, Array[Symbol]

        # Used with power-to-heat to defines the profile used to shape demand.
        attribute :demand_profile, Symbol

        # If this node acts on behalf of another in the Merit order, attributes
        # (such as capacity) will be taken from the named delegate instead of
        # this node.
        attribute :delegate, Symbol

        # Sets a percentage of production load to be curtailed. For example, if
        # this is set to 0.2, the top 20% of the profile will be removed.
        attribute :production_curtailment, Float

        # Used only on price-sensitive demands; controls whether to use
        # dispatchables when meeting the demand of the participant.
        attribute :satisfy_with_dispatchables, Boolean, writer: :public

        # Used by always-on battery parks to name related nodes in the technology.
        attribute :relations, Hash[Symbol => Symbol], default: nil

        # Use with load shifting to specify an upper-capacity limit on how much
        # load can be shifted. Since the capacity is calculated dynamically
        # based on the demand sources, this is expressed as multiple of output
        # capacity. i.e. if the output capacity is 10 MW and the limit is set
        # to 50, then the load shifting limit will be 500 MWh.
        attribute :load_shifting_hours, Float
      end

      validates :level, inclusion: %i[lv mv hv omit]

      validates :production_curtailment, absence: true, if: (lambda do |mo|
        mo.type != :producer || !%i[must_run volatile].include?(mo.subtype)
      end)

      validates :relations, presence: true, if: (lambda do |mo|
        mo.type == :producer && mo.subtype == :always_on_battery_park
      end)

      validates :satisfy_with_dispatchables,
        exclusion: {
          in: [true, false],
          message: 'is only allowed when type=flex and subtype=export'
        },
        unless: ->(mo) { mo.type == :flex && mo.subtype == :export }

      def self.producer_subtypes
        @producer_subtypes = (super + %i[import always_on_battery_park]).freeze
      end

      def self.consumer_subtypes
        @consumer_subtypes = (super + %i[electricity_loss]).freeze
      end

      validates :load_shifting_hours,
        absence: { message: 'is only allowed when type=flex and subtype=export' },
        unless: ->(mo) { mo.type == :flex && mo.subtype == :load_shifting }

      validates :load_shifting_hours,
        numericality: {
          greater_than_or_equal_to: 0,
          less_than_or_equal_to: 8760
        },
        allow_nil: true,
        if: ->(mo) { mo.type == :flex && mo.subtype == :load_shifting }

      validate :validate_load_shifting_config

      def attributes
        attrs = super
        attrs.delete(:demand_source) if attrs[:demand_source].empty?
        attrs
      end

      private

      # Validates that demand sources named in a load shifting node are valid for use as a demand
      # source.
      def validate_load_shifting_config
        return unless type == :flex && subtype == :load_shifting

        source_nodes = Array(demand_source)

        if source_nodes.empty?
          errors.add(:demand_source, 'must be set and contain at least one node')
        end

        source_nodes.each do |node|
          if !Atlas::EnergyNode.exists?(node)
            errors.add(:demand_source, "contains node #{node} which does not exist")
          elsif Atlas::EnergyNode.find(node).merit_order&.type != :consumer
            errors.add(:demand_source, "contains node #{node} which is not a consumer node")
          end
        end
      end
    end
  end
end
