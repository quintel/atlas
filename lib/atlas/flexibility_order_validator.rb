# frozen_string_literal: true

module Atlas
  # Asserts that the named attribute contains only values named in the
  # flexibility order configuration file.
  class FlexibilityOrderValidator < ActiveModel::Validator
    def validate(record)
      validate_unique(record)
      validate_allowed(record)
    end

    private

    # Internal: Asserts that no flexibility option is specified more than
    # once.
    def validate_unique(record)
      return if provided(record).uniq.length == provided(record).length

      record.errors.add(
        options[:attribute],
        'contains a flexibility option more than once'
      )
    end

    # Internal: Asserts that all of the flexibility options are named in the
    # config file.
    def validate_allowed(record)
      unknown = provided(record) - allowed

      return if unknown.empty?

      record.errors.add(
        options[:attribute],
        "contains unknown flexibility options: #{unknown.join(', ')}"
      )
    end

    def provided(record)
      Array(record.public_send(options[:attribute]))
    end

    def allowed
      allowed = options[:in]
      allowed.respond_to?(:call) ? allowed.call : allowed
    end
  end
end
