module Atlas
  class GraphExporter < Exporter
    def to_h
      super.to_yaml
    end

    private

    def nodes_hash(nodes)
      nodes.each_with_object({}) do |node, result|
        result[node.key] = node.properties
          .except(:model).merge({ in: {}, out: {} })

        node.slots.each do |slot_collection|
          direction = result[node.key][slot_collection.direction]

          slot_collection.each do |slot|
            direction[slot.carrier] = slot.properties.except(:model)
          end
        end
      end
    end

    def edges_hash(edges)
      edges.each_with_object({}) do |edge, result|
        edge_key = edge.properties[:model].key

        result[edge_key] = edge.properties.except(:model)
      end
    end
  end
end
