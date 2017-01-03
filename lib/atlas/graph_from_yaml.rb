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
      graph_nodes.each_pair do |node, attributes|
        attributes.fetch(:node).each_pair do |attr, val|
          node.set(attr, val)
        end

        attributes.fetch(:slot).each_pair do |direction, attributes|
          update_slots(node.slots.public_send(direction), attributes)
        end
      end

      edges.each do |edge|
        edge.properties.merge!(properties_for_edge(edge))
      end

      @graph
    end

    private

    def graph_nodes
      Hash[@graph.nodes.map do |node|
        attributes       = @graph_yaml.fetch(:nodes)[node.key] || {}
        node_attributes  = attributes.slice!(:in, :out)

        [ node, { slot: attributes, node: node_attributes } ]
      end]
    end

    def update_slots(slots, attributes)
      attributes.each_pair do |slot_key, share|
        ref_slot = get_slot(slots, slot_key)

        if share.is_a?(Numeric)
          ref_slot.set(:share, share)
        else
          ref_slot.set(:type, share)
        end
      end
    end

    def get_slot(slots, slot_key)
      if slots.include?(slot_key)
        slots.get(slot_key)
      else
        slots.add(slot_key)
      end
    end

    def edges
      @edges ||= @graph.nodes.map { |node| node.out_edges.to_a }.flatten
    end

    def properties_for_edge(edge)
      @graph_yaml.fetch(:edges).detect { |key, _|
        key == edge.properties[:model].key
      }.last
    end
  end
end
