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
    #        will typically be a +MessagePack.unpack+'ed copy of the output from
    #        the +Exporter+.
    #
    # Returns a ProductionMode
    def initialize(data)
      @data = data
    end

    # Public: An array containing all of the nodes with the pre-calculated demands for nodes
    # belonging to the energy graph.
    #
    # Returns a ActiveDocument::Collection of nodes.
    def energy_nodes
      @energy_nodes ||= collection(GraphConfig.energy.node_class)
    end

    # Public: An array containing all of the nodes with the pre-calculated demands for nodes
    # belonging to the molecule graph.
    #
    # Returns a ActiveDocument::Collection of nodes.
    def molecule_nodes
      @molecule_nodes ||= collection(GraphConfig.molecules.node_class)
    end

    # Public: An array containing all of the edges with the pre-calculated demands for edges
    # belonging to the energy graph.
    #
    # Returns ActiveDocument::Collection of edges.
    def energy_edges
      @energy_edges ||= collection(GraphConfig.energy.edge_class)
    end

    # Public: An array containing all of the edges with the pre-calculated demands for edges
    # belonging to the molecule graph.
    #
    # Returns ActiveDocument::Collection of edges.
    def molecule_edges
      @molecule_edges ||= collection(GraphConfig.molecules.edge_class)
    end

    # Public: An array containing all of the carriers with pre-calculated dataset-specific query
    # attributes.
    #
    # Returns ActiveDocument::Collection of carriers.
    def carriers
      @carriers ||= collection(Atlas::Carrier)
    end

    private

    def collection(klass)
      Collection.new(ActiveDocument::ProductionManager.new(klass, @data[klass.name] || {}).all)
    end
  end
end
