module Atlas
  # A special way to load nodes and edges with pre-calculated demands and
  # shares. This is used in ETEngine since it isn't possible to perform the
  # Rubel queries and Refinery calculations and still respond to a request in
  # a timely manner.
  #
  # The "static" data (in the ./static directory) for the chosen region is
  # loaded and merged with the data in the ActiveDocument Files.
  #
  # ProductionMode only has special loaders for Nodes and Edges; all other
  # ActiveDocument classes can be used as normal.
  #
  # For example:
  #
  #   ProductionMode.new(:nl).nodes
  #   # => #<Atlas::Collection (493 x Atlas::Node)>
  class ProductionMode
    # Public: Creates a new ProductionMode instance.
    #
    # data - A hash containing production data for the nodes and edges. This
    #        will typically be a +YAML.load_file+'d copy of the output from
    #        the +Exporter+.
    #
    # Returns a ProductionMode
    def initialize(data)
      @data = { nodes: {}, edges: {} }.merge(data)
    end

    # Public: An array containing all of the nodes with the pre-calculated
    # demands.
    #
    # Returns an array of nodes.
    def nodes
      @nodes ||= Collection.new(
        ActiveDocument::ProductionManager.new(Node, @data[:nodes]).all)
    end

    # Public: An array containing all of the edges with the pre-calculated
    # demands.
    #
    # Returns an array of edges.
    def edges
      @edges ||= Collection.new(
        ActiveDocument::ProductionManager.new(Edge, @data[:edges]).all)
    end
  end # ProductionMode
end # Atlas
