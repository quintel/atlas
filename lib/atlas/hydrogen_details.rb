module Atlas
  # Contains information about a nodes participantion in the time-resolved
  # hydrogen calculation.
  class HydrogenDetails
    include ValueObject
    include ActiveModel::Validations

    values do
      attribute :type,    Symbol, writer: :public
      attribute :profile, Symbol, writer: :public
    end

    validates :type, inclusion: %i[consumer producer storage]

    validates :profile, presence: true, if: ->(hd) { hd.type != :storage }
    validates :profile, absence: true,  if: ->(hd) { hd.type == :storage }
  end
end
