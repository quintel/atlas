module Atlas
  class Scaler::GraphExporter
    def initialize(refinery_graph)
      @refinery_graph = refinery_graph
    end

    def export
      @refinery_graph.nodes
        .each_with_object(data, &method(:transform_nodes)).to_yaml
    end

    private

    def data
      { nodes: {}, edges: {} }
    end

    def transform_nodes(node, result)
      result[:nodes][node.key] = node.properties
        .except(:model).merge({ in: {}, out: {} })

      node.slots.each do |slot_collection|
        direction = result[:nodes][node.key][slot_collection.direction]

        slot_collection.each do |slot|
          direction[slot.carrier] = slot.properties.except(:model)
        end
      end

      node.edges(:out).each do |edge|
        edge_key = edge.properties[:model].key

        result[:edges][edge_key] = edge.properties.except(:model)
      end
    end
  end
end
