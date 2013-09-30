module Atlas
  # Given a fully calculated graph, exports the demand and share data so that
  # it can be used by Atlas's production mode (in ETEngine).
  class Exporter
    # Public: Given a graph, returns the Hash with all the exported values.
    #
    # graph - A Turbine::Graph containing the calculated Refinery nodes and
    #         edges.
    #
    # Returns a Hash for you to save as you see fit.
    def self.dump(graph)
      new(graph).to_h
    end

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

    # Public: Creates the hash of calculated attributes for nodes and edges.
    #
    # Returns a hash.
    def to_h
      nodes = @graph.nodes
      edges = nodes.map { |node| node.out_edges.to_a }.flatten

      { nodes: nodes_hash(nodes), edges: edges_hash(edges) }
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
        model      = node.get(:model)
        attributes = model.to_hash

        attributes.merge!(node.properties.except(:model, :cc_in, :cc_out))

        if model.merit_order
          attributes[:merit_order] = model.merit_order.to_hash
        end

        if model.max_demand
          attributes[:max_demand] = model.max_demand
        else
          attributes.delete(:max_demand)
        end

        attributes[:demand] = node.demand.to_f
        attributes[:input]  = slots_hash(node.slots.in)
        attributes[:output] = slots_hash(node.slots.out)

        attributes.delete(:queries)

        hash[node.key] = attributes
      end
    end

    # Internal: Given an array of +edges+, and a +path+ to which to write,
    # creates a CSV containing all of the edge shares.
    #
    # Returns nothing.
    def edges_hash(edges)
      data = edges.each_with_object({}) do |edge, hash|
        model      = edge.get(:model)

        attributes = model.to_hash
        attributes[:child_share] = edge.child_share.to_f

        if model.type == :constant
          attributes[:demand] = edge.demand.to_f
        elsif model.type == :share && model.reversed?
          attributes[:parent_share] = edge.parent_share.to_f
        end

        attributes.delete(:queries)

        hash[model.key] = attributes
      end

      # Yay coupling carrier special cases!
      Edge.all.each do |edge|
        if edge.carrier == :coupling_carrier
          data[edge.key] = edge.to_hash
          data[edge.key][:share] = edge.child_share
        end
      end

      data
    end

    # Internal: Given a collection of slots, creates a hash with the shares of
    # each slot.
    #
    # slots - An array containing slots.
    #
    # Returns a hash.
    def slots_hash(slots)
      node      = slots.node
      direction = slots.direction

      from_slots = slots.each_with_object({}) do |slot, hash|
        if slot.get(:model).is_a?(Atlas::Slot::Elastic)
          hash[slot.carrier] = :elastic
        else
          hash[slot.carrier] = slot.share.to_f
        end
      end

      if slots.any?
        # Find any temporarily stored coupling carrier conversion.
        if cc_share = node.get(:"cc_#{ direction }")
          from_slots[:coupling_carrier] = cc_share
        end
      end

      from_slots
    end
  end # Exporter
end # Atlas
