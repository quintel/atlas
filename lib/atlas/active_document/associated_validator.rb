# frozen_string_literal: true

module Atlas
  module ActiveDocument
    # Validates another ActiveModel which is an attribute on the record.
    class AssociatedValidator < ActiveModel::Validator
      def validate(record)
        associated = record.public_send(options[:attribute])

        return true if associated.nil? || associated.valid?

        associated.errors.each do |error, msg|
          message = if error.respond_to?(:full_message)
            # ActiveModel::Error
            error.full_message
          else
            "#{error} #{msg}"
          end

          record.errors.add(options[:attribute], message)
        end
      end
    end
  end
end
