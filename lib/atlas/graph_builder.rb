module Atlas
  class GraphBuilder
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

    private

    # Internal: Creates a new GraphBuilder. Use GraphBuilder.build rather than
    # creating this yourself.
    #
    # Returns a GraphBuilder.
    def initialize(sector = nil)
      @nodes = Collection.new(Node.all.select(&filter(sector)))
      @graph = Turbine::Graph.new

      @edges = if sector
        Collection.new(Edge.all.select do |edge|
          # For the moment, we test the sector of the node on each end of the
          # edge, rather than the namespace of the edge; edges currently use
          # the same namespace as the parent node. Because of this, testing
          # only the namespace would raise a DocumentNotFoundError when trying
          # to connect "bridge" edges which cross from one sector to another.
          @nodes.key?(edge.supplier) || @nodes.key?(edge.consumer)
        end)
      else
        Edge.all
      end
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

        self.class.establish_edge(edge, @graph, @nodes)
      end
    end

    # Internal: Given a +graph+ and a node +document+ adds a Node to the
    # Turbine graph representing the document.
    #
    # Returns nothing.
    def add_node(graph, document)
      unless graph.node(document.key)
        node = graph.add(Refinery::Node.new(document.key, model: document))
        establish_slots(node, document)
      end
    end

    # Internal: Adds slots to the each node whenever the slot does not already
    # exist. This is necessary since some nodes may define a slot without
    # connecting any edges (e.g. loss outputs).
    #
    # Returns nothing.
    def establish_slots(node, document)
      (document.out_slots + document.in_slots).each do |slot|
        next if slot.carrier == :coupling_carrier

        collection = node.slots.public_send(slot.direction)

        ref_slot =
          if collection.include?(slot.carrier)
            collection.get(slot.carrier)
          else
            collection.add(slot.carrier)
          end

        ref_slot.set(:model, slot)
        ref_slot.set(:type, :elastic) if slot.is_a?(Slot::Elastic)
      end
    end

    # Internal: Given a single +edge+, sets up the edge between the two
    # nodes specified.
    #
    # edge - An Edge (ActiveDocument) instance.
    #
    # Returns the Turbine::Edge which was created.
    def self.establish_edge(edge, graph, nodes)
      parent  = graph.node(edge.supplier)
      child   = graph.node(edge.consumer)
      carrier = Carrier.find(edge.carrier)

      props = edge.attributes.slice(
        :parent_share, :child_share, :demand, :reversed, :priority
      ).merge(model: edge)

      if edge.type == :inversed_flexible
        # Send energy to the sink only once all the other edges have had their
        # demands set.
        props[:type] = :overflow
      elsif edge.type == :flexible
        # Receive energy from the source once all the other input edges have
        # had their demand set.
        props[:type] = :flexible
      end

      fail DocumentNotFoundError.new(edge.supplier, Node) if parent.nil?
      fail DocumentNotFoundError.new(edge.consumer, Node) if child.nil?

      parent.connect_to(child, carrier.key, props)
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
        ->(el) { el.ns && el.ns.match(regex) }
      else
        ->(el) { true }
      end
    end
  end
end
