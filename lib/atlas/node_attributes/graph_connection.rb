# frozen_string_literal: true

module Atlas
  module NodeAttributes
    # Configures conversion from flows in one ETEngine graph to another.
    #
    # Used to allow a demand in the energy graph to be used to set a demand in the molecule graph,
    # and vice-versa.
    class GraphConnection
      include ValueObject
      include ActiveModel::Validations

      # Valid directions. Direction may be left blank.
      DIRECTIONS = %i[input output].freeze

      values do
        # The key of the energy node which will be used to determine the conversion of energy to
        # molecules.
        attribute :source, Symbol

        # Indicates whether to convert the inputs or outputs of the source node when determining the
        # molecule demand. Optional.
        #
        # For example, when using a `conversion` from electricity, set direction to "input" to use
        # the input of electricity to the source node, "output" to use the output of electricity, or
        # blank to use the source node demand.
        attribute :direction, Symbol

        # Describes how to convert the inputs or outputs of the source node to molecules.
        #
        # The value should be either a numeric, which will be used to adjust the conversion of demand
        # to molecules, or a hash when converting inputs or outputs.
        #
        # Any carriers used by the source node not explicitly included in the `conversion` hash will
        # be ignored, and not result in any molecule demand.
        #
        # For example, when `direction` is set to "input" and the source node has coal and biomass
        # input carriers, you may set:
        #
        #   - molecule_conversion.conversion.coal = 0.7
        #   - molecule_conversion.conversion.biomass = 0.5
        #
        # This results in a hash: `{ coal: 0.7, biomass: 0.5 }` this means that 70% of the input of
        # coal and 50% of the biomass will be converted to a molecule flow. If the source node
        # receives 100 coal, 50 biomass, and 10 network gas, the resulting molecule demand will be
        # 95 (70 [from coal] + 25 [from biomass] + 0 [from gas]).
        #
        # When `direction` is not set, the source node demand is used to determine the molecule
        # demand. `conversion` may be set to a Numeric:
        #
        #   - molecule_conversion.conversion = 0.5
        #
        # Required when `direction` is set to "input" or "output"; should be blank otherwise.
        attribute :conversion, Hash[Symbol => Float], default: nil
      end

      validates_inclusion_of :direction, in: DIRECTIONS, allow_nil: true

      validates_presence_of :conversion,
        if: -> { DIRECTIONS.include?(direction) },
        message: "can't be blank when direction is one of: #{DIRECTIONS.join(', ')}"

      validate :validate_type_of_conversion, if: :conversion

      # Public: Returns the conversion of a named carrier.
      def conversion_of(carrier)
        return 1.0 if conversion.nil?
        return conversion if conversion.is_a?(Numeric)

        raise MoleculeCarrierRequired if carrier.nil?

        conversion[carrier.to_sym] || 0.0
      end

      def source_class_name
        raise NotImplementedError
      end

      private

      def validate_type_of_conversion
        if DIRECTIONS.include?(direction) && !conversion.is_a?(Hash)
          errors.add(:conversion, "must name each carrier when direction is #{direction}")
        elsif direction.nil? && conversion.is_a?(Hash)
          errors.add(:conversion, 'must be numeric when direction has no value')
        end
      end
    end

    # Represents connections from the energy graph to the molecule graph.
    class EnergyToMolecules < GraphConnection
      validates_with ActiveDocument::DocumentReferenceValidator,
        attribute: :source,
        class_name: 'Atlas::EnergyNode'
    end

    # Represents connections from the molecule graph to the energy graph.
    class MoleculesToEnergy < GraphConnection
      validates_with ActiveDocument::DocumentReferenceValidator,
        attribute: :source,
        class_name: 'Atlas::MoleculeNode'
    end
  end
end
