module Atlas
  class GraphBuilder
    # A list of nodes which should be ignored and not included in the graph.
    IGNORE = %w(
      energy_chp_ultra_supercritical_coal
      energy_power_ultra_supercritical_coal
    ).map(&:to_sym).freeze

    ALSO = {
      industry: %w(
        energy_distribution_coal_gas
        energy_cokesoven_transformation_coal
        energy_steel_blastfurnace_bat_transformation_cokes
        energy_steel_blastfurnace_current_transformation_cokes )
    }.freeze

    # Public: Creates a Turbine::Graph containing all the nodes in the data
    # files, and sets up the edges between them.
    #
    # Each node has a "model" property containing the ActiveDocument instance.
    def self.build(sector = nil)
      new(sector).graph
    end

    # Public: The graph, built by GraphBuilder.
    #
    # Returns a Turbine::Graph containing the nodes and edges defined in the
    # source files.
    def graph
      if @graph.nodes.empty?
        build_nodes!
        establish_edges!
      end

      @graph
    end

    #######
    private
    #######

    # Internal: Creates a new GraphBuilder. Use GraphBuilder.build rather than
    # creating this yourself.
    #
    # Returns a GraphBuilder.
    def initialize(sector = nil)
      @nodes = Collection.new(Node.all.select(&filter(sector)))
      @graph = Turbine::Graph.new

      edges = if sector
        Edge.all.select do |edge|
          # For the moment, we test the sector of the node on each end of the
          # edge, rather than the namespace of the edge; edges currently use
          # the same namespace as the parent node. Because of this, testing
          # only the namespace would raise a DocumentNotFoundError when trying
          # to connect "bridge" edges which cross from one sector to another.
          in_sector = @nodes.key?(edge.supplier) || @nodes.key?(edge.consumer)

          in_sector &&
            ! IGNORE.include?(edge.supplier) &&
            ! IGNORE.include?(edge.consumer)
        end
      else
        Edge.all
      end

      @edges = Collection.new(edges)
    end

    # Internal: Adds the ActiveDocument nodes to the Turbine graph.
    #
    # Returns nothing.
    def build_nodes!
      @nodes.sort_by(&:key).each { |node| add_node(@graph, node) }
    end

    # Internal: Reads the source files to set up the edges between each node.
    #
    # Returns nothing.
    def establish_edges!
      @edges.sort_by(&:key).each do |edge|
        next if edge.carrier == :coupling_carrier

        unless @nodes.key?(edge.consumer)
          add_node(@graph, Atlas::Node.new(key: :SUPER_SINK))
        end

        unless @nodes.key?(edge.supplier)
          add_node(@graph, Atlas::Node.new(key: :SUPER_SOURCE))
        end

        self.class.establish_edge(edge, @graph, @nodes)
      end

      # Produce simpler graphs; whenever a super-source child has only
      # incoming edges from the super-source, get rid of them.
      if super_source = @graph.node(:SUPER_SOURCE)
        super_source.out_edges.each do |edge|
          if edge.child.in_edges.all? { |o| o.from.key == :SUPER_SOURCE }
            edge.from.disconnect_via(edge)
          end
        end

        @graph.delete(super_source) if super_source.out_edges.none?
      end
    end

    # Internal: Given a +graph+ and a node +document+ adds a Node to the
    # Turbine graph representing the document.
    #
    # Returns nothing.
    def add_node(graph, document)
      unless graph.node(document.key)
        graph.add(Turbine::Node.new(document.key, model: document))
      end
    end

    # Internal: Given a single +edge+, sets up the edge between the two
    # nodes specified.
    #
    # edge - An Edge (ActiveDocument) instance.
    #
    # Returns the Turbine::Edge which was created.
    def self.establish_edge(edge, graph, nodes)
      parent  = graph.node(edge.supplier) || graph.node(:SUPER_SOURCE)
      child   = graph.node(edge.consumer) || graph.node(:SUPER_SINK)
      carrier = Carrier.find(edge.carrier)

      props = edge.attributes.slice(
        :parent_share, :child_share, :demand, :reversed
      ).merge(model: edge)

      if child.key == :SUPER_SINK || edge.type == :inverse_flexible
        # Send energy to the sink only once all the other edges have had their
        # demands set.
        props[:type] = :overflow
      elsif edge.type == :flexible
        # Receive energy from the source once all the other input edges have
        # had their demand set.
        props[:type] = :flexible
      end

      if parent.nil?
        raise DocumentNotFoundError.new(edge.supplier, Node)
      end

      parent.connect_to(child, carrier.key, props)
    rescue Turbine::DuplicateEdgeError => ex
      # Ignore duplicate edges to or from the super-nodes
      raise ex if parent.key != :SUPER_SOURCE && child.key != :SUPER_SINK
    end

    # Internal: Given a sector, returns a lambda which can be used to filter
    # the edges and nodes so that only those in the sector are selected.
    #
    # sector - The sector name as a string.
    #
    # Returns a lambda.
    def filter(sector)
      if sector
        regex = /^#{ Regexp.escape(sector.to_s) }\.?/

        ->(el) {
          ( (el.ns && el.ns.match(regex) && ! IGNORE.include?(el.key)) ||
            (ALSO[sector] && ALSO[sector].include?(el.key.to_s)) )
        }
      else
        ->(el) { true }
      end
    end
  end # GraphBuilder
end # Atlas
