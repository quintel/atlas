# frozen_string_literal: false

module Atlas
  class Node
    # Asserts that a nodes Fever configuration is valid.
    class FeverValidator < ActiveModel::Validator
      MESSAGES = {
        balanced_with_blank:
          'fever.efficiency_balanced_with must not be blank when ' \
          'fever.efficiency_based_on is set',
        missing_slot:
          'fever.%s expects a %s slot, but none was present'
      }.freeze

      def validate(record)
        return true unless record.fever

        fever = record.fever

        validate_variable_efficiency(record, fever) if fever.efficiency_based_on
      end

      private

      def validate_variable_efficiency(record, fever)
        validate_slot_presence(record, :efficiency_based_on)

        if fever.efficiency_balanced_with.blank?
          record.errors.add(:fever, MESSAGES[:balanced_with_blank])
        else
          validate_slot_presence(record, :efficiency_balanced_with)
        end
      end

      def validate_slot_presence(record, attr)
        carrier = record.fever.public_send(attr)

        return if record.in_slots.any? { |s| s.carrier == carrier }

        record.errors.add(
          :fever, format(MESSAGES[:missing_slot],attr, carrier)
        )
      end
    end # FeverValidator
  end # Node
end # Atlas
