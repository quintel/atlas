module Atlas
  class MeritOrderDetails
    include Virtus.value_object

    values do
      attribute :type,  Symbol
      attribute :group, Symbol
    end

    # Public: The merit order details as a hash, with any nil attributes not
    # present.
    #
    # Returns a hash.
    def to_hash
      attrs = attributes
      attrs.delete_if { |_, value| value.nil? }

      attrs
    end
  end # MeritOrderDetails
end # Atlas
