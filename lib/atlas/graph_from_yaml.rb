module Atlas
  class GraphFromYaml
    def self.build(graph_yaml)
      new(graph_yaml).build_graph
    end

    def initialize(graph_yaml)
      @graph_yaml = graph_yaml
      @graph      = Refinery::Catalyst::FromTurbine.call(GraphBuilder.build)
    end

    def build_graph
      graph_nodes.each do |node, node_attributes, slot_attributes|
        node_attributes.each_pair do |attr, val|
          node.set(attr, val)
        end

        update_slots(node.slots.in, slot_attributes[:in])
        update_slots(node.slots.out, slot_attributes[:out])
      end

      edges.each do |edge|
        edge.properties.merge!(properties_for_edge(edge))
      end

      @graph
    end

    private

    def graph_nodes
      @graph.nodes.map do |node|
        attributes = @graph_yaml.fetch(:nodes)[node.key] || {}

        [ node,
          attributes.except(:in, :out),
          attributes.slice(:in, :out) ]
      end
    end

    def update_slots(slots, attributes)
      attributes.each_pair do |carrier, share_attributes|
        ref_slot = if slots.include?(carrier)
          slots.get(carrier)
        else
          slots.add(carrier)
        end

        ref_slot.properties = share_attributes
      end
    end

    def edges
      @graph.nodes.map { |node| node.out_edges.to_a }.flatten
    end

    def properties_for_edge(edge)
      @graph_yaml.fetch(:edges)[edge.properties[:model].key]
    end
  end
end
