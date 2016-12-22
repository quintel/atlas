module Atlas
  # Given a (usually fully calculated, i.e. Refined) graph, exports
  # the demand and share data and most of Atlas' node attributes,
  # so that it can be used by Atlas' production mode (in ETEngine).
  class FullExporter < Exporter

    private

    # Internal: Given an array of +nodes+, creates a hash containing all
    # of the node demands and attributes.
    #
    # Returns a Hash.
    def nodes_hash(nodes)
      nodes.each_with_object({}) do |node, hash|
        model      = node.get(:model)
        attributes = model.to_hash

        attributes.merge!(node.properties.except(:model, :cc_in, :cc_out))

        attributes.each do |key, value|
          attributes[key] = value.to_hash if value.is_a?(ValueObject)
        end

        if model.max_demand
          attributes[:max_demand] = model.max_demand
        elsif ! model.queries.key?(:max_demand)
          # Keep the Refinery value if it was set by a query.
          attributes.delete(:max_demand)
        end

        attributes[:demand] = node.demand.to_f
        attributes[:input]  = slots_hash(node.slots.in)
        attributes[:output] = slots_hash(node.slots.out)

        attributes.delete(:queries)

        hash[node.key] = attributes
      end
    end

    # Internal: Given an array of +edges+, creates a hash containing all
    # of the edge shares.
    #
    # Returns a Hash.
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
    # Returns a Hash.
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
  end # FullExporter
end # Atlas
