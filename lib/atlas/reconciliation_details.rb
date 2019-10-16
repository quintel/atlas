# frozen_string_literal: true

module Atlas
  # Contains information about a nodes participantion in the time-resolved
  # balanced supply/demand calculation.
  class ReconciliationDetails
    include ValueObject
    include ActiveModel::Validations

    attr_reader :carrier

    values do
      attribute :type,     Symbol, writer: :public
      attribute :profile,  Symbol, writer: :public
      attribute :behavior, Symbol, writer: :public
    end

    validates :type, inclusion: %i[consumer producer storage]

    validates :profile, presence: true, if: ->(rd) { rd.type != :storage }
    validates :profile, absence: true,  if: ->(rd) { rd.type == :storage }
  end
end
