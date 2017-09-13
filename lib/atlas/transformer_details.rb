module Atlas
  class TransformerDetails
    include ValueObject

    values do
      # Flag which tells if the node or edge should be editable through
      # the interface of ETLocal
      attribute :editable, Boolean, default: false

      # Flag which tells if the node or edge should be in the route of
      # the transformation
      attribute :whitelisted, Boolean, default: -> (node,_) { node.editable? || false }
    end
  end # StorageDetails
end # Atlas
