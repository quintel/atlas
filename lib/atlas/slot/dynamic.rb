# frozen_string_literal: true

module Atlas
  class Slot
    # Dynamic slots have no special behavior in Atlas or Refinery, but in
    # ETEngine have their conversions calculated dynamically by looking at the
    # flow of energy through all the node's edges.
    #
    # See Qernel::Slot::LinkBased in quintel/etengine.
    class Dynamic < Slot
      # Public: The share of energy which leaves the node through this slot.
      # Calculated in Refinery, so it remains nil here.
      #
      # Returns nil.
      def share
        nil
      end

      # Internal: Determines if a given share indicates that a slot should be
      # dynamic.
      #
      # Returns true or false.
      def self.dynamic?(share)
        share.to_s == 'etengine_dynamic'
      end
    end
  end
end
