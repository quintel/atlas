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
          'fever.%s expects a %s slot, but none was present',
        alias_missing:
          'fever.alias_of must be the name of a Fever node',
        alias_invalid:
          'fever.alias_of must be the name of a hot water node',
        missing_capacity:
          'fever.capacity must be set on a hybrid node',
        illegal_capacity:
          'fever.capacity must not be set on non-hybrid node'
      }.freeze

      def validate(record)
        return true unless record.fever

        fever = record.fever

        validate_variable_efficiency(record, fever) if fever.efficiency_based_on
        validate_alias_of(record, fever) if fever.alias_of
        validate_capacity(record, fever)
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
          :fever, format(MESSAGES[:missing_slot], attr, carrier)
        )
      end

      def validate_alias_of(record, fever)
        if !Node.exists?(fever.alias_of) || !Node.find(fever.alias_of).fever
          record.errors.add(:fever, MESSAGES[:alias_missing])
        elsif Node.find(fever.alias_of).fever.group != :hot_water
          record.errors.add(:fever, MESSAGES[:alias_invalid])
        end
      end

      def validate_capacity(record, fever)
        if record.key.to_s.include?('hybrid')
          if !fever.capacity || fever.capacity.values.none?
            record.errors.add(:fever, MESSAGES[:missing_capacity])
          end
        elsif fever.capacity && fever.capacity.values.any?
          record.errors.add(:fever, MESSAGES[:illegal_capacity])
        end
      end
    end # FeverValidator
  end # Node
end # Atlas
