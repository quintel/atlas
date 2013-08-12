module Atlas
  class Slot
    # Elastic slots fill whatever share is left by the other slots. For
    # example, if a node has two other output slots with a share of 0.2 and
    # 0.4, the elastic slot's share will be 0.4.
    class Elastic < Slot
      ELASTIC_STR = 'elastic'

      validate :validate_data

      # Public: The share of energy which leaves the node through this slot.
      # Calculated in Refinery, so it remains nil here.
      #
      # Returns nil.
      def share
        nil
      end

      #######
      private
      #######

      # Internal: The sibling slots (those on the same "side" of the node)
      # which are not elastic.
      #
      # Returns a collection of Slots.
      def inelastic_slots
        node.out_slots - [self]
      end

      # Internal: Asserts that the slot is the only elastic slot on the node.
      #
      # Returns nothing.
      def validate_data
        if inelastic_slots.any? { |s| s.is_a?(Slot::Elastic) }
          errors.add(:base, 'cannot have more than one elastic slot')
        end
      end

      # Internal: Determines if a given share indicates that a slot should be
      # elastic.
      #
      # Returns true or false.
      def self.elastic?(share)
        share == :elastic || share == ELASTIC_STR
      end
    end # Elastic
  end # Slot
end # Atlas
