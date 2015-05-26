module Atlas
  class StorageDetails
    include ValueObject

    values do
      # The total amount which may be stored, in Wh.
      attribute :volume, Float

      # The amount by which the stored amount decreases each hour, in W.
      attribute :decay, Float, default: 0.0
    end
  end # StorageDetails
end # Atlas
