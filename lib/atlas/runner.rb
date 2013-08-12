module Atlas
  # Acts as a controller for building the fully-calculated graph.
  #
  # Loads the graph structure and attributes from the source files, calculates
  # the Rubel-based attributes, triggers the Refinery calculations, and
  # returns to results to you.
  class Runner
    attr_reader :dataset, :graph

    # Iterates through each node in the graph, converting the "efficiency"
    # attribute, if present, to the appropriate slot shares.
    SetSlotSharesFromEfficiency = lambda do |query|
      lambda do |refinery|
        refinery.nodes.each do |node|
          model = node.get(:model)

          (model.out_slots + model.in_slots).each do |slot|
            collection = node.slots.public_send(slot.direction)

            next if slot.carrier == :coupling_carrier

            if collection.include?(slot.carrier)
              ref_slot = collection.get(slot.carrier)
            else
              ref_slot = collection.add(slot.carrier)
            end

            ref_slot.set(:model, slot)
            ref_slot.set(:type, :elastic) if slot.is_a?(Slot::Elastic)

            if slot.query
              ref_slot.set(:share, query.call(slot.query))
            elsif slot.share
              ref_slot.set(:share, slot.share)
            end
          end
        end

        refinery
      end
    end

    # Public: Creates a new Runner.
    #
    # Returns a Runner.
    def initialize(dataset, graph)
      @dataset = dataset
      @graph   = graph

      Atlas.load_library('refinery')
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate(with = Refinery::Catalyst::Calculators)
      Refinery::Reactor.new(
        with, Refinery::Catalyst::Validation
      ).run(refinery_graph)
    end

    # Public: Returns the Refinery graph which the Runner uses to calculate
    # missing attributes.
    #
    # Returns a Turbine::Graph.
    def refinery_graph
      @refinery ||= begin
        graph.nodes.each do |node|
          calculate_rubel_attributes!(node)

          node.out_edges.each do |edge|
            calculate_rubel_attributes!(edge)
          end
        end

        Refinery::Reactor.new(
          Refinery::Catalyst::FromTurbine,
          SetSlotSharesFromEfficiency.call(method(:query))
        ).run(graph)
      end
    end

    # Public: The runtime used by the Runner to calculate Rubel attributes.
    #
    # Returns an Atlas::Runtime.
    def runtime
      @runtime ||= Runtime.new(dataset, graph)
    end

    #######
    private
    #######

    # Internal: Given an +element+ from the graph -- a node or edge --
    # calculate any Rubel queries which are defined on the associated
    # ActiveDocument.
    def calculate_rubel_attributes!(element)
      model = element.get(:model)

      model.queries && model.queries.each do |attribute, rubel_string|
        element.set(attribute, query(rubel_string))
      end
    end

    # Internal: Executes the given Rubel query +string+, returning the
    # result.
    def query(string)
      result = runtime.execute(string)

      unless result.is_a?(Numeric) || result.nil?
        fail NonNumericQueryError.new(result)
      end

      result
    rescue RuntimeError => ex
      ex.message.gsub!(/$/, " (executing: #{ string.inspect })")
      raise ex
    end

  end # Runner
end # Atlas
