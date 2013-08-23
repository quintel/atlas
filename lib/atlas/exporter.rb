module Atlas
  # Given a fully calculated graph, exports the demand and share data so that
  # it can be used by Atlas's production mode (in ETEngine).
  class Exporter
    # Public: Creates a new exporter. Does not check that the graph has been
    # calculated; it is expected you'll run the graph through Runner first,
    # which will raise errors if the graph is not fully calculated.
    #
    # graph - The graph which will be exported.
    #
    # Returns an Exporter.
    def initialize(graph)
      @graph = graph
    end

    # Public: Writes the calculated values in the graph to CSV files in the
    # given directory.
    #
    # dir - Path to the directory in which to write the CSV files.
    #
    # Returns nothing.
    def export_to(path)
      FileUtils.mkdir_p(path.dirname)

      nodes = @graph.nodes
      edges = nodes.map { |node| node.out_edges.to_a }.flatten

      path.open('w') do |file|
        file.write(YAML.dump(
          nodes: nodes_hash(nodes),
          edges: edges_hash(edges)))
      end

      nil
    end

    #######
    private
    #######

    # Internal: Given an array of +nodes+, and a +path+ to which to write,
    # creates a CSV containing all of the node demands.
    #
    # Returns nothing.
    def nodes_hash(nodes)
      nodes.each_with_object({}) do |node, hash|
        hash[node.key] = node.properties.except(:model).merge!({
          demand: node.demand.to_f,
          input:  slots_hash(node.slots.in),
          output: slots_hash(node.slots.out)
        })
      end
    end

    # Internal: Given an array of +edges+, and a +path+ to which to write,
    # creates a CSV containing all of the edge shares.
    #
    # Returns nothing.
    def edges_hash(edges)
      edges.each_with_object({}) do |edge, hash|
        hash[Atlas::Edge.key(edge.child.key, edge.parent.key, edge.label)] =
          { child_share: edge.child_share.to_f }
      end
    end

    # Internal: Given a collection of slots, creates a hash with the shares of
    # each slot.
    #
    # slots - An array containing slots.
    #
    # Returns a hash.
    def slots_hash(slots)
      from_slots = slots.each_with_object({}) do |slot, hash|
        hash[slot.carrier] = slot.share.to_f
      end

      if slots.any?
        # Find any temporarily stored coupling carrier conversion.
        node      = slots.first.node
        direction = slots.first.direction

        if cc_share = node.get(:"cc_#{ direction }")
          from_slots[:coupling_carrier] = cc_share
        end
      end

      from_slots
    end
  end # Exporter
end # Atlas
