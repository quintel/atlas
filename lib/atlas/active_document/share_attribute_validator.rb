module Atlas
  module ActiveDocument
    # Asserts that a document has values set for several attributes whose values
    # should sum to 1.0. Missing values is considered an error.
    #
    # For example
    #   class MyDoc
    #     include ActiveDocument
    #
    #     validate_sith ShareAttributeValidator,
    #       attributes: %i( heater_1_share heater_2_share heater_3_share ),
    #       name: 'heater share'
    #
    class ShareAttributeValidator < ActiveModel::Validator
      def validate(record)
        return false unless validate_presence(record)

        sum = share_attributes.sum { |name| record.public_send(name) }

        unless sum.between?(0.99, 1.01)
          record.errors.add(
            options.fetch(:group),
            "contains #{ options.fetch(:group) } attributes which sum to " \
            "#{ sum }, but should sum to 1.0"
          )
        end
      end

      private

      def share_attributes
        options.fetch(:attributes)
      end

      def validate_presence(record)
        all_present = true

        share_attributes.each do |name|
          if record.public_send(name).nil?
            record.errors.add(name, 'is not a number')
            all_present = false
          end
        end

        all_present
      end
    end
  end
end
