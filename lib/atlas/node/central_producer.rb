module Atlas
  class Node::CentralProducer < Node::Demand
    # Public: The query used to extract a demand from the central producers
    # CSV data.
    #
    # Returns a string.
    def queries
      {
        demand:          "CENTRAL_PRODUCTION(#{ key }, demand)",
        full_load_hours: "CENTRAL_PRODUCTION(#{ key }, full_load_hours)",
      }.merge(super)
    end
  end # Node::CentralProducer
end # Atlas
