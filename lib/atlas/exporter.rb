module Atlas
  # Given a graph, exports its data as a Hash for serialization.
  #
  # This is an abstract base class. An implementation must provide
  # the following methods:
  #  - nodes_hash(nodes)
  #  - edges_hash(edges)
  class Exporter
    # Public: Given a graph, returns the Hash with all the exported values.
    #
    # graph - A Turbine::Graph containing the nodes and edges.
    #
    # Returns a Hash for you to save as you see fit.
    def self.dump(graph)
      new(graph).to_h
    end

    # Public: Creates a new exporter. Does not care if the graph has been
    # calculated; it is expected you'll run the graph through Runner first
    # if needed, which will raise errors if the graph is not fully calculated.
    #
    # graph - The graph which will be exported.
    #
    # Returns an Exporter.
    def initialize(graph)
      @graph = graph
    end

    # Public: Creates the hash of attributes for nodes and edges.
    #
    # Returns a Hash.
    def to_h
      nodes = @graph.nodes
      edges = nodes.map { |node| node.out_edges.to_a }.flatten

      { nodes: nodes_hash(nodes), edges: edges_hash(edges) }
    end
  end # Exporter
end # Atlas
