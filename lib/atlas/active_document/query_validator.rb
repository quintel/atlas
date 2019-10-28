# frozen_string_literal: true

module Atlas
  module ActiveDocument
    # Asserts that a document defines a query for at least one of the given
    # attributes, or that a static value is present. Disallows the presence of
    # both a query and static value.
    class QueryValidator < ActiveModel::Validator
      BOTH    = 'cannot be both a query and attribute'
      MISSING = 'must define a :attrs attribute or query'

      def validate(record)
        all_blank = !options.fetch(:allow_no_query, false)

        options[:attributes].each do |attr|
          has_query = record.queries.key?(attr)
          has_attr  = record.public_send(attr)

          if has_query && has_attr
            record.errors.add(attr, BOTH)
          elsif has_query || has_attr
            all_blank = false
          end
        end

        if all_blank
          sentence     = options[:attributes].dup
          sentence[-1] = "or #{sentence[-1]}" if sentence.length > 1
          sentence     = sentence.join(', ')

          record.errors.add(:base, MISSING.gsub(':attrs', sentence))
        end
      end
    end
  end
end
