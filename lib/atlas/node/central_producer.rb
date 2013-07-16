module Atlas
  class Node::CentralProducer < Node::Demand
    # Public: The query used to extract a demand from the central producers
    # CSV data.
    #
    # Returns a string.
    def query
      "CENTRAL_PRODUCTION(#{ key })"
    end

    # Public: Queries for central producers always set a value for the demand
    # attribute.
    #
    # Returns a Symbol.
    def sets
      :demand
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
    def full_load_hours(area)
      Dataset.find(area).central_producers.get(key, :full_load_hours)
    end
  end # Node::CentralProducer
end # Atlas
