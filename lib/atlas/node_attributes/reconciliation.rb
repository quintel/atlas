# frozen_string_literal: true

module Atlas
  module NodeAttributes
    # Contains information about a nodes participantion in the time-resolved
    # balanced supply/demand calculation.
    class Reconciliation
      include ValueObject
      include ActiveModel::Validations

      attr_reader :carrier

      values do
        attribute :type,     Symbol, writer: :public
        attribute :profile,  Symbol, writer: :public
        attribute :behavior, Symbol, writer: :public

        # Set a custom carrier to be used for the calculation of demand.
        attribute :demand_carrier, Symbol, writer: :public

        # Sets that the reconciliation of this node is affected by an input
        # curve on another "leader" node. The leader node key should be
        # specified as the value for "subordinate_to".
        attribute :subordinate_to, Symbol, writer: :public

        # The output carrier on both this node and the leader. This will be used
        # to fetch the output curve from the leader and to fetch the output
        # conversion on the subordinate.
        attribute :subordinate_to_output, Symbol, writer: :public
      end

      validates :type, inclusion: %i[consumer producer storage]

      validates :profile, presence: true, if: -> { type != :storage }
      validates :profile, absence: true,  if: -> { type == :storage }

      # When the node is a subordinate...
      validates_with ActiveDocument::DocumentReferenceValidator,
        attribute: :subordinate_to,
        class_name: 'Atlas::Node',
        if: -> { behavior == :subordinate }

      validate :validate_subordinate_behavior

      validates :subordinate_to_output, presence: true, if: :subordinate_to

      # When the node is not a subordinate...
      validates :subordinate_to,
        absence: true, if: -> { behavior != :subordinate }

      validates :subordinate_to_output, absence: true, unless: :subordinate_to

      def validate_subordinate_behavior
        if type != :consumer && behavior == :subordinate
          errors.add(
            :behavior,
            'must not be subordinate unless type is consumer'
          )
        end
      end
    end
  end
end
