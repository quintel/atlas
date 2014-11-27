module Atlas
  class Node::CentralProducer < Node::Demand
    # Public: The query used to extract a demand from the central producers
    # CSV data.
    #
    # Returns a string.
    def queries
      super.merge(demand: "CENTRAL_PRODUCTION(#{ key })")
    end

    # Public: The number of hours in each year for which the producer is
    # running.
    #
    # area - An area code; the full_load_hours differs depending on the
    #        region. You must supply the area code so that we know which
    #        region's value to retrieve.
    #
    # Returns a float, or raises a UnknownCSVRowError if the producer does
    # not exist in the "central_producers.csv" file.
    def full_load_hours(area = nil)
      # Allow area to be nil for +to_hash+.
      return nil if area.nil?

      Dataset.find(area).central_producers.get(key, :full_load_hours)
    end

    # Public: Creates a hash containing the document's attributes, omitting
    # those whose values are nil, as well as full_load_hours and query, since
    # those are dynamic. Also ignores the demand query which is auto-set by
    # the node.
    #
    # Returns a Hash.
    def to_hash
      hash = super

      hash.delete(:full_load_hours)
      hash.delete(:query)
      hash.delete(:sets)

      hash
    end
  end # Node::CentralProducer
end # Atlas
