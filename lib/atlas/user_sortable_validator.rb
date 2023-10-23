# frozen_string_literal: true

module Atlas
  # Asserts that the named attribute contains only values named in the
  # flexibility order configuration file.
  class UserSortableValidator < ActiveModel::Validator
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
        'contains an option more than once'
      )
    end

    # Internal: Asserts that all of the flexibility options are named in the
    # config file.
    def validate_allowed(record)
      unknown = provided(record) - allowed(record)

      return if unknown.empty?

      record.errors.add(
        options[:attribute],
        "contains unknown options: #{unknown.join(', ')}"
      )
    end

    def provided(record)
      Array(record.public_send(options[:attribute]))
    end

    def allowed(record)
      allowed = options[:in]
      allowed.respond_to?(:call) ? call_with_options(allowed, record) : allowed
    end

    def call_with_options(allowed_order, record)
      allowed_order.call(options_for_allowed(record))
    end

    def options_for_allowed(record)
      param = options[:with]
      param = param.respond_to?(:call) ? param.call : param
      param ? record.public_send(param) : nil
    end
  end
end
