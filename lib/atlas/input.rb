module Atlas
  class Input
    include ActiveDocument
    include InputHelper

    attribute :query,           String
    attribute :share_group,     Symbol
    attribute :label,           String
    attribute :label_query,     String
    attribute :comments,        String
    attribute :priority,        Integer, default: 0

    attribute :max_value,       Float
    attribute :max_value_gql,   String
    attribute :min_value,       Float
    attribute :min_value_gql,   String
    attribute :start_value,     Float
    attribute :start_value_gql, String
    attribute :step_value,      Float
    attribute :factor,          Float

    attribute :unit,            String
    attribute :update_period,   String
    attribute :update_type,     String
    attribute :default_unit,    String
    attribute :dependent_on,    String

    attribute :disabled_by,     Array[Symbol]
    attribute :coupling_groups, Array[Symbol]

    validates_presence_of :query, if: ->{ share_group.blank? }

    validate :validate_query_within_group,
      if: ->{ ! share_group.blank? && ! query }

    validates_presence_of :share_group, allow_nil: true,
      message: 'must be blank, or have a value of non-zero length'

    validates_presence_of :update_period

    validate :validate_enum_input
    validate :validate_disabled_inputs
    validate :validate_disallowed_gql

    private

    # Internal: Validates that INPUT_VALUE is not used in any GQL used to initialize inputs.
    #
    # Returns nothing.
    def validate_disallowed_gql
      %i[start_value_gql min_value_gql max_value_gql].each do |attribute|
        if public_send(attribute).to_s.include?('INPUT_VALUE')
          errors.add(attribute, 'cannot contain INPUT_VALUE')
        end
      end
    end

    # Internal: Asserts that the inputs named in `disabled_by` all exist and update a compatible
    # period.
    #
    # Returns nothing.
    def validate_disabled_inputs
      validator = DocumentReferenceValidator.new
      disabled_periods = update_period == 'both' ? %w[present future both] : [update_period]

      Array(disabled_by).each do |other_key|
        validator.validate_reference(
          self,
          other_key,
          attribute: 'disabled_by',
          class_name: 'Atlas::Input'
        )

        next unless Atlas::Input.exists?(other_key)

        other = Atlas::Input.find(other_key)

        next if disabled_periods.include?(other.update_period)

        errors.add(
          :disabled_by,
          "cannot include #{other.key.to_s.inspect} because it does not update " \
          "#{disabled_periods.join(' or ')} period"
        )
      end
    end

    # Internal: Asserts that a query is defined on the Input.
    #
    # A query may be omitted only if the input belongs to a share group and all
    # the other inputs have a query defined.
    #
    # Returns nothing.
    def validate_query_within_group
      unless (self.class.by_share_group[share_group] - [self]).all?(&:query)
        errors.add(:query, :blank)
      end
    end

    # Asserts that an input with permitted_values or type=enum has the necessary
    # data.
    def validate_enum_input
      return if unit != 'enum' || !min_value_gql.blank?

      errors.add(:min_value_gql, 'must not be blank when the unit is "enum"')
    end
  end # Input
end # Atlas
