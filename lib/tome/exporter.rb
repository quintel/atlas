module Tome
  # Given a fully calculated graph, exports the demand and share data so that
  # it can be used by Tome's production mode (in ETEngine).
  class Exporter
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

    # Public: Writes the calculated values in the graph to CSV files in the
    # given directory.
    #
    # dir - Path to the directory in which to write the CSV files.
    #
    # Returns nothing.
    def export_to(path)
      FileUtils.mkdir_p(path.dirname)

      nodes = @graph.nodes
      edges = nodes.map { |node| node.out_edges.to_a }.flatten

      path.open('w') do |file|
        file.write(YAML.dump(
          nodes: nodes_hash(nodes),
          edges: edges_hash(edges)))
      end

      nil
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
        hash[node.key] = {
          demand: node.demand.to_f,
          slots:  slots_hash(node)
        }
      end
    end

    # Internal: Given an array of +edges+, and a +path+ to which to write,
    # creates a CSV containing all of the edge shares.
    #
    # Returns nothing.
    def edges_hash(edges)
      edges.each_with_object({}) do |edge, hash|
        hash[Tome::Edge.key(edge.parent.key, edge.child.key, edge.label)] = {
          child_share: edge.child_share.to_f
        }
      end
    end

    # Internal: Given a node, creates a hash with the shares of each +in+ and
    # +out+ slot on the node.
    #
    # node - The node whose slots are to be dumped to a hash.
    #
    # Returns a hash.
    def slots_hash(node)
      hash = { in: {}, out: {} }

      hash.each do |direction, collection|
        node.slots.public_send(direction).each do |slot|
          collection[slot.carrier] = slot.share.to_f
        end
      end

      hash
    end
  end # Exporter
end # Tome
