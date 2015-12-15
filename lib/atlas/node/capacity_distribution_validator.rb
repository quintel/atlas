module Atlas
  class Node
    # When a capacity_distribution is assigned, ensures that the necessary
    # network attributes also have values.
    class CapacityDistributionValidator < ActiveModel::Validator
      MESSAGE = 'must not be blank when a capacity_distribution is present'
      ATTRS = [:network_capacity_available_in_mw, :network_capacity_used_in_mw]

      def validate(record)
        return true unless record.capacity_distribution

        ATTRS.each do |attr|
          record.errors.add(attr, MESSAGE) unless record.public_send(attr)
        end
      end
    end # CapacityDistributionValidator
  end # Node
end # Atlas
