module Atlas
  class GraphDeserializer
    # Public: build method
    #
    # Takes a +graph_hash+ as an argument. A +graph_hash+ looks like:
    #
    # {
    #   edges: {
    #     <key> : { .. }
    #   },
    #   nodes: {
    #     <key> : {
    #       in: { .. },
    #       out: { .. },
    #       ...
    #     }
    #   }
    # }
    #
    def self.build(graph_hash)
      new(graph_hash).build_graph
    end

    private_class_method :new

    def initialize(graph_hash)
      @graph_hash = graph_hash
      @graph      = GraphBuilder.build
    end

    def build_graph
      graph_nodes.each do |node, node_attributes, slot_attributes|
        node_attributes.each_pair do |key, val|
          node.set(key, val)
        end

        update_slots(node, node.slots.in, slot_attributes[:in])
        update_slots(node, node.slots.out, slot_attributes[:out])
      end

      edges.each do |edge|
        properties_for_edge(edge).each_pair do |key, val|
          edge.set(key, val)
        end
      end

      @graph
    end

    private

    def graph_nodes
      @graph.nodes.map do |node|
        attributes = @graph_hash.fetch(:nodes)[node.key] || {}

        [ node,
          attributes.except(:in, :out),
          attributes.slice(:in, :out) ]
      end
    end

    def update_slots(node, slots, attributes)
      attributes.each_pair do |carrier, share_attributes|
        slot = find_refinery_slot(slots, carrier)

        slot.set(:model,
          Slot.slot_for(node.get(:model), slot.direction, carrier))

        share_attributes.each_pair do |key, val|
          slot.set(key, val)
        end
      end
    end

    def find_refinery_slot(slots, carrier)
      if slots.include?(carrier)
        slots.get(carrier)
      else
        slots.add(carrier)
      end
    end

    def edges
      @graph.nodes.map { |node| node.out_edges.to_a }.flatten
    end

    def properties_for_edge(edge)
      @graph_hash.fetch(:edges)[edge.properties[:model].key]
    end
  end
end
