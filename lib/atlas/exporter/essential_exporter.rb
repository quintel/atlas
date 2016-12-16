module Atlas
  # Given a (usually initial, i.e. pre-Refined) graph, exports
  # the demand and share data (and thus all the dataset/country-specific
  # data), so that it can be used for long-term storage of a (derived)
  # dataset - independent of the country-specific data files (CSVs etc).
  class EssentialExporter < Exporter
    def self.dump(graph, scaling_factor)
      new(graph, scaling_factor).to_h
    end

    def initialize(graph, scaling_factor)
      @graph          = graph
      @scaling_factor = scaling_factor
    end

    private

    # Internal: Given an array of +nodes+, creates a hash containing all
    # of the node demands and slot shares.
    #
    # References for the choice of node properties:
    # https://github.com/quintel/atlas/issues/59#issuecomment-265736310
    # https://github.com/quintel/internal/issues/5#issuecomment-265120551
    #
    # Returns a Hash.
    def nodes_hash(nodes)
      nodes.each_with_object({}) do |node, hash|
        attributes      = node.properties
        node_attributes = attributes.except(:model)

        node_attributes[:in]  = slots_hash(node.slots.in)
        node_attributes[:out] = slots_hash(node.slots.out)

        hash[node.key] = node_attributes
      end
    end

    # Internal: Given an array of +edges+, creates a hash containing all
    # of the edge shares.
    #
    # Returns a Hash.
    def edges_hash(edges)
      edges.each_with_object({}) do |edge, hash|
        edge_key = edge.properties[:model].key

        hash[edge_key] = edge.properties.except(:model)
      end
    end

    # Internal: Given a collection of slots, creates a hash with the shares of
    # each slot.
    #
    # Returns a hash.
    def slots_hash(slots)
      slots.each_with_object({}) do |slot, hash|
        slot.properties.slice(:share, :type).each do |_, val|
          hash[slot.carrier] = val
        end
      end
    end
  end # EssentialExporter
end # Atlas
