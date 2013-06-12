module Tome
  # Acts as a controller for building the fully-calculated graph.
  #
  # Loads the graph structure and attributes from the source files, calculates
  # the Rubel-based attributes, triggers the Refinery calculations, and
  # returns to results to you.
  class Runner
    attr_reader :dataset, :graph

    # Creates a Refinery catalyst which, given the initial Refinery graph,
    # will set the share values for any slots where a share is explicitly
    # specified, or calculated through a Rubel query.
    #
    # It expects to be called with a lambda telling the catalyst how to run
    # the Rubel query.
    #
    #   SetSlotShares.call(->(query) { runtime.execute(query) })
    #   # => #<TheRefineryCatalyst ...>
    #
    # Returns a lambda.
    SetSlotSharesFromDocuments = ->(perform) do
      ->(refinery) do
        Slot.all.each do |model|
          node     = refinery.node(model.node) || next
          node_doc = node.get(:model)
          coll     = node.slots.public_send(model.direction)

          if coll.include?(model.carrier)
            slot = coll.get(model.carrier)
          else
            # Loss slots frequently have no edges, so they won't have been
            # auto-created by Refinery.
            slot = coll.add(model.carrier)
          end

          if model.query
            slot.set(:share, perform.call(model.query))
          elsif model.share
            slot.set(:share, model.share)
          end
        end

        refinery
      end
    end # SetSlotSharesFromDocuments

    # Iterates through each node in the graph, converting the "efficiency"
    # attribute, if present, to the appropriate slot shares.
    #
    # Shares set by SetSlotSharesFromDocuments (i.e., those which are hard-
    # coded into the documents, or come from a Rubel calculation, are not
    # overwritten.
    SetSlotSharesFromEfficiency = ->(refinery) do
      refinery.nodes.each do |node|
        node.get(:model).efficiency.each do |carrier, share|
          if node.slots.out.include?(carrier)
            slot = node.slots.out.get(carrier)
          else
            slot = node.slots.out.add(carrier)
          end

          slot.set(:share, share) if slot.get(:share).nil?
        end
      end

      refinery
    end

    # Public: Creates a new Runner.
    #
    # Returns a Runner.
    def initialize(dataset, graph)
      @dataset = dataset
      @graph   = graph

      Tome.load_library('refinery')
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate
      Refinery::Reactor.new(
        Refinery::Catalyst::Calculators,
        Refinery::Catalyst::Validation
      ).run(refinery_graph)
    end

    # Public: Returns the Refinery graph which the Runner uses to calculate
    # missing attributes.
    #
    # Returns a Turbine::Graph.
    def refinery_graph
      @refinery ||= begin
        graph.nodes.each do |node|
          calculate_rubel_attribute(node, :demand)

          node.out_edges.each do |edge|
            calculate_rubel_attribute(edge, edge.get(:model).sets)
          end
        end

        Refinery::Reactor.new(
          Refinery::Catalyst::FromTurbine,
          SetSlotSharesFromDocuments.call(method(:query)),
          SetSlotSharesFromEfficiency
        ).run(graph)
      end
    end

    # Public: The runtime used by the Runner to calculate Rubel attributes.
    #
    # Returns an Tome::Runtime.
    def runtime
      @runtime ||= Runtime.new(dataset, graph)
    end

    #######
    private
    #######

    # Internal: Given an +element+ and +attribute+ name, if the element has a
    # "query" attribute, that query will be run with Rubel at the resulting
    # values set to +attribute+.
    #
    # For example
    #
    #    calculate_rubel_attribute(node, :demand)
    #
    # Returns nothing.
    def calculate_rubel_attribute(element, attribute)
      model = element.get(:model)

      if model.respond_to?(:query) && ! model.query.nil?
        element.set(attribute, query(model.query))
      end
    end

    def query(string)
      unless (result = runtime.execute(string)).is_a?(Numeric)
        raise NonNumericQueryError.new(result)
      end

      result
    rescue RuntimeError => ex
      ex.message.gsub!(/$/, " (executing: #{ string.inspect })")
      raise ex
    end

  end # Runner
end # Tome
