module Atlas
  module ActiveDocument
    class SerializedGraphValidator < ActiveModel::Validator
      def validate(record)
        return false if skip_validations?(record)

        graph = GraphDeserializer.new(YAML.load_file(record.graph_path))

        validate_nodes(record, graph)
        validate_edges(record, graph)
        validate_slots(record, graph)
      end

      private

      def skip_validations?(record)
        record.new_record? || record.errors[:graph].any?
      end

      # Internal: validate_nodes(record)
      #
      # Adds an error for all missing nodes.
      def validate_nodes(record, graph)
        missing_nodes = (graph.graph.nodes.map(&:key) -
                         graph.graph_hash.fetch(:nodes).keys)

        if missing_nodes.any?
          record.errors.add(:graph, "the following nodes are missing in the" \
            " snapshot of the graph: #{ missing_nodes.join(", ") }")
        end
      end

      # Internal: validate_edges(record)
      #
      # Adds an error for all missing edges.
      def validate_edges(record, graph)
        missing_edges = (graph.edges.map{ |e| e.properties[:model].key } -
                         graph.graph_hash.fetch(:edges).keys)

        if missing_edges.any?
          record.errors.add(:graph, "the following edges are missing in the" \
            " snapshot of the graph: #{ missing_edges.join(", ") }")
        end
      end

      # Internal: validate_slots(record)
      #
      # Adds an error for every set of missing slots per node.
      # Compares the carriers that are present in the GraphBuilder node to
      # the 'in', 'out' carriers for a perticular node in the 'graph.yml'.
      def validate_slots(record, graph)
        graph.graph.nodes.flat_map do |node|
          if slot_hash = graph.graph_hash.fetch(:nodes)[node.key]
            missing_slots = (node.slots.flat_map(&:to_a).map(&:carrier) -
                             slot_hash.slice(:in, :out).values.flat_map(&:keys))

            if missing_slots.any?
              record.errors.add(:graph, "the following slots for " \
                "#{ node.key } are missing in the snapshot of the graph: "\
                "#{ missing_slots.join(", ") }")
            end
          end
        end
      end
    end
  end
end
