module Tome
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
  #   # => #<Tome::Collection (493 x Tome::Node)>
  class ProductionMode
    # Public: Creates a new ProductionMode instance.
    #
    # area - The area code whose static data will be used.
    #
    # Returns a ProductionMode
    def initialize(area)
      @area = area.to_sym
    end

    # Public: An array containing all of the nodes with the pre-calculated
    # demands.
    #
    # Returns an array of nodes.
    def nodes
      @nodes ||= Collection.new(
        ActiveDocument::ProductionManager.new(Node, @area).all)
    end

    # Public: An array containing all of the edges with the pre-calculated
    # demands.
    #
    # Returns an array of edges.
    def edges
      @edges ||= Collection.new(
        ActiveDocument::ProductionManager.new(Edge, @area).all)
    end
  end # ProductionMode
end # Tome
