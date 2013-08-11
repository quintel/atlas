module Atlas
  class Node
    include ActiveDocument

    DIRECTORY = 'nodes'

    attribute :use,                  String
    attribute :has_loss,             Boolean
    attribute :energy_balance_group, String
    attribute :demand,               Float

    attribute :query,                String
    attribute :input,                Hash[Symbol => Object]
    attribute :output,               Hash[Symbol => Object]

    alias_method :sector,  :ns
    alias_method :sector=, :ns=

    # Numeric attributes.
    [ :availability,
      :co2_free,
      :demand_expected_value,
      :forecasting_error,
      :full_load_hours,
      :households_supplied_per_unit,
      :land_use_per_unit,
      :part_ets,
      :part_load_efficiency_penalty,
      :part_load_operating_point,
      :variability,
      :electricity_output_capacity,
      :heat_output_capacity,
      :preset_demand,
      :expected_demand,
      :average_effective_output_of_nominal_capacity_over_lifetime
    ].each do |name|
      attribute name, Float
    end

    # Deprecated: Since a few months ago, electrical efficiency arrives as
    # separate attributes from the CSVs, but is converted into a hash by the
    # xls2yml script.
    attribute :electrical_efficiency_when_using_coal, Float
    attribute :electrical_efficiency_when_using_wood_pellets, Float

    validate :validate_slots

    # ------------------------------------------------------------------------

    # Public: A set containing all of the infor this node. Input slots are
    # created by adding a key/pair of carrier/share to the node's "input"
    # attribute.
    #
    # For example
    #
    #   node.input = { gas: 0.4 }
    #   node.in_slots
    #   # => [ #<Atlas::Slot key="node-@gas" share=0.4> ]
    #
    # Returns a set containing slots.
    def in_slots
      @in_slots ||= Set.new(
        input.merge(dynamic_slots(:input)).map do |carrier, _|
          Slot.slot_for(self, :in, carrier)
        end)
    end

    # Public: A set containing all of the output slots for this node. Output
    # slots are created by adding a key/pair of carrier/share to the node's
    # "output" attribute.
    #
    # For example
    #
    #   node.output = { gas: 0.4 }
    #   node.out_slots
    #   # => [ #<Atlas::Slot key="node-@gas" share=0.4> ]
    #
    # Returns a set containing slots.
    def out_slots
      @out_slots ||= Set.new(
        output.merge(dynamic_slots(:output)).map do |carrier, _|
          Slot.slot_for(self, :out, carrier)
        end)
    end

    # Public: Sets the input share data for the node. This controls how demand
    # from the node is routed.
    #
    # For example:
    #
    #   # 40% of the energy which enters the node leaves as gas, 30% will
    #   # leave as electricity. Any remaining is considered to be "loss".
    #   node.input = { gas: 0.4, electricity: 0.3 }
    #
    # Returns whatever you gave.
    def input=(inputs)
      super
      @in_slots = nil
    end

    # Public: Sets the output share data for the node. This controls how
    # energy leaving the node is routed.
    #
    # For example:
    #
    #   # 40% of the energy which enters the node leaves as gas, 30% will
    #   # leave as electricity. Any remaining is considered to be "loss".
    #   node.output = { gas: 0.4, electricity: 0.3 }
    #
    # Returns whatever you gave.
    def output=(outputs)
      super
      @out_slots = nil
    end

    #######
    private
    #######

    # Internal: Asserts the input and output slot data is in a valid format.
    #
    # Returns nothing.
    def validate_slots
      in_slots.reject(&:valid?).each do |slot|
        slot.errors.full_messages.each { |msg| errors.add(:input, msg) }
      end

      out_slots.reject(&:valid?).each do |slot|
        slot.errors.full_messages.each { |msg| errors.add(:output, msg) }
      end
    end

    # Internal: Creates a hash representing slots whose shares are set via
    # a Rubel query.
    #
    # Returns a hash.
    def dynamic_slots(direction)
      direction = direction.to_s

      Hash[ queries
        .select { |key, _| key.to_s.start_with?(direction) }
        .map { |key, _| [key.to_s.split('.', 2).last.to_sym, nil] } ]
    end

  end # Node
end # Atlas
