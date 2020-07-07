# frozen_string_literal: true

module Atlas
  # A base module for Node classes.
  module Node
    extend ActiveSupport::Concern

    included do
      include ActiveDocument

      attribute :input,                  Hash[Symbol => Object]
      attribute :output,                 Hash[Symbol => Object]
      attribute :groups,                 Array[Symbol]
      attribute :use,                    String
      attribute :presentation_group,     Symbol
      attribute :graph_methods,          Array[String]
      attribute :waste_outputs,          Array[Symbol]
      attribute :scaling_exempt,         Virtus::Attribute::Boolean

      # Numeric attributes.
      attribute :availability,           Float
      attribute :demand,                 Float
      attribute :demand_expected_value,  Float
      attribute :expected_demand,        Float
      attribute :full_load_hours,        Float
      attribute :input_efficiency,       Float
      attribute :max_demand,             Float
      attribute :number_of_units,        Float
      attribute :output_efficiency,      Float
      attribute :preset_demand,          Float
      attribute :typical_input_capacity, Float

      validates_with ActiveDocument::QueryValidator,
        attributes: [:max_demand], allow_no_query: true

      validate :validate_slots
      validate :validate_waste_outputs

      alias_method :sector,  :ns
      alias_method :sector=, :ns=

      include InstanceMethods
    end

    # ----------------------------------------------------------------------------------------------

    # Contains methods defined on the class which includes Node.
    module ClassMethods
      # Public: Returns the GraphConfig::Config object which has information about the graph to
      # which the node belongs.
      def graph_config
        raise NotImplementedError
      end
    end

    # ----------------------------------------------------------------------------------------------

    # InstanceMethods have to be defined in a separate module, and included at the end of the
    # above `included` block, otherwise the Virtus attributes will override any custom
    # implementation (such as `input=`).
    module InstanceMethods
      # Public: A set containing all of the input slots for this node. Input slots are created by
      # adding a key/pair of carrier/share to the node's "input" attribute.
      #
      # For example
      #
      #   node.input = { gas: 0.4 }
      #   node.in_slots
      #   # => [ #<Atlas::Slot carrier="gas" direction="in" share=0.4> ]
      #
      # Returns a set containing slots.
      def in_slots
        @in_slots ||= Set.new(
          input.merge(dynamic_slots(:input)).map do |carrier, _|
            Slot.slot_for(self, :in, carrier)
          end
        )
      end

      # Public: A set containing all of the output slots for this node. Output slots are created by
      # adding a key/pair of carrier/share to the node's "output" attribute.
      #
      # For example
      #
      #   node.output = { gas: 0.4 }
      #   node.out_slots
      #   # => [ #<Atlas::Slot carrier="gas" direction="out" share=0.4> ]
      #
      # Returns a set containing slots.
      def out_slots
        @out_slots ||= Set.new(
          output.merge(dynamic_slots(:output)).map do |carrier, _|
            Slot.slot_for(self, :out, carrier)
          end
        )
      end

      # Public: Sets the input share data for the node.
      #
      # For example:
      #
      #   # 40% of the energy which enters the node leaves as gas, 30% will leave as electricity.
      #   # Any remaining is considered to be "loss".
      #   node.input = { gas: 0.4, electricity: 0.3 }
      #
      # Returns whatever you gave.
      def input=(inputs)
        super
        @in_slots = nil
      end

      # Public: Sets the output share data for the node.
      #
      # For example:
      #
      #   # 40% of the energy which enters the node leaves as gas, 30% will leave as electricity.
      #   # Any remaining is considered to be "loss".
      #   node.output = { gas: 0.4, electricity: 0.3 }
      #
      # Returns whatever you gave.
      def output=(outputs)
        super
        @out_slots = nil
      end

      # See Edge.graph_config
      def graph_config
        self.class.graph_config
      end

      private

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

      # Internal: Asserts that the output carriers named in `waste_outputs` exist as an output.
      #
      # Returns nothing.
      def validate_waste_outputs
        return if waste_outputs.empty?

        valid_carriers = out_slots.map(&:carrier)

        waste_outputs.each do |carrier_key|
          if carrier_key == :loss
            errors.add(:waste_outputs, 'must not include loss')
          elsif !valid_carriers.include?(carrier_key)
            errors.add(
              :waste_outputs,
              "includes a non-existent output carrier: #{carrier_key}"
            )
          end
        end
      end

      # Internal: Creates a hash representing slots whose shares are set via a Rubel query.
      #
      # Returns a hash.
      def dynamic_slots(direction)
        direction = direction.to_s

        Hash[ queries
          .select { |key, _| key.to_s.start_with?(direction) }
          .map { |key, _| [key.to_s.split('.', 2).last.to_sym, nil] } ]
      end
    end

    # ----------------------------------------------------------------------------------------------

    def self.all
      EnergyNode.all + MoleculeNode.all
    end
  end
end
