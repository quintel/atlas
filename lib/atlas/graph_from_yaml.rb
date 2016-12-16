module Atlas
  class GraphFromYaml
    def self.build(graph_yaml)
      new(graph_yaml).build_graph
    end

    def initialize(graph_yaml)
      @graph_yaml = graph_yaml
      @graph      = GraphBuilder.build
    end

    def build_graph
      @graph.nodes.each do |node|
        if node_attributes = @graph_yaml.fetch(:nodes)[node.key]
          atlas_node        = node.get(:model)
          atlas_node.input  = node_attributes[:in]
          atlas_node.output = node_attributes[:out]

          node_attributes.except(:in, :out).each_pair do |attr, val|
            node.set(attr, val)
          end

          set_slots(atlas_node, node_attributes.slice(:in, :out))
        end
      end

      edges.each do |edge|
        edge.properties.merge!(properties_for_edge(edge))
      end

      @graph
    end

    private

    def set_slots(node, node_attributes)
      node_attributes.each_pair do |direction, slot_attributes|
        slot_collection = node.public_send("#{ direction }_slots")

        slot_attributes.each_pair do |slot_key, share_attributes|
          slot_collection.add(Atlas::Slot.new(
            node: node,
            direction: direction,
            carrier: slot_key
          ))
        end
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
