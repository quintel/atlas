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
        graph_nodes = graph.graph.nodes.map(&:key)
        yaml_nodes  = graph.graph_hash.fetch(:nodes).keys

        compare(graph_nodes, yaml_nodes) do |nodes|
          add_errors_for_added_nodes(record, nodes.added)
          add_errors_for_removed_nodes(record, nodes.removed)
        end
      end

      def add_errors_for_added_nodes(record, nodes)
        return if nodes.empty?

        record.errors.add(:graph, 'the following nodes are missing in the' \
          " snapshot of the graph: #{nodes.join(', ')}")
      end

      def add_errors_for_removed_nodes(record, nodes)
        return if nodes.empty?

        record.errors.add(:graph, 'the following nodes are missing in the' \
          " graph: #{nodes.join(', ')}")
      end

      # Internal: validate_edges(record)
      #
      # Adds an error for all missing edges.
      def validate_edges(record, graph)
        graph_edges = graph.edges.map { |e| e.properties[:model].key }
        yaml_edges  = graph.graph_hash.fetch(:edges).keys

        compare(graph_edges, yaml_edges) do |edges|
          add_errors_for_added_edges(record, edges.added)
          add_errors_for_removed_edges(record, edges.removed)
        end
      end

      def add_errors_for_added_edges(record, edges)
        return if edges.empty?

        record.errors.add(:graph, 'the following edges are missing in the' \
          " snapshot of the graph: #{edges.join(', ')}")
      end

      def add_errors_for_removed_edges(record, edges)
        return if edges.empty?

        record.errors.add(:graph, 'the following edges are missing in the' \
          " graph: #{edges.join(', ')}")
      end

      # Internal: validate_slots(record)
      #
      # Adds an error for every set of missing slots per node.
      # Compares the carriers that are present in the GraphBuilder node to
      # the 'in', 'out' carriers for a perticular node in the 'graph.yml'.
      def validate_slots(record, graph)
        graph.graph.nodes.each do |node|
          slot_hash   = graph.graph_hash.fetch(:nodes)[node.key] || {}
          graph_slots = node.slots.flat_map(&:to_a).map(&:carrier)
          yaml_slots  = slot_hash.slice(:in, :out).values.flat_map(&:keys)

          compare(graph_slots, yaml_slots) do |slots|
            add_errors_for_added_slots(record, node, slots.added)
            add_errors_for_removed_slots(record, node, slots.removed)
          end
        end
      end

      def add_errors_for_added_slots(record, node, slots)
        return if slots.empty?

        record.errors.add(:graph, 'the following slots for ' \
          "#{node.key} are missing in the snapshot of the graph: "\
          "#{slots.join(', ')}")
      end

      def add_errors_for_removed_slots(record, node, slots)
        return if slots.empty?

        record.errors.add(:graph, 'the following slots for ' \
          "#{node.key} are missing in the graph: "\
          "#{slots.join(', ')}")
      end

      def compare(graph_parts, yaml_parts)
        yield(OpenStruct.new(
          added:   (graph_parts - yaml_parts),
          removed: (yaml_parts  - graph_parts)
        ))
      end
    end
  end
end
