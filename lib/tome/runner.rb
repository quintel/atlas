module Tome
  # Acts as a controller for building the fully-calculated graph.
  #
  # Loads the graph structure and attributes from the source files, calculates
  # the Rubel-based attributes, triggers the Refinery calculations, and
  # returns to results to you.
  class Runner
    attr_reader :dataset, :graph

    # Iterates through each node in the graph, converting the "efficiency"
    # attribute, if present, to the appropriate slot shares.
    SetSlotSharesFromEfficiency = ->(refinery) do
      refinery.nodes.each do |node|
        model = node.get(:model)

        (model.out_slots + model.in_slots).each do |slot|
          collection = node.slots.public_send(slot.direction)

          if collection.include?(slot.carrier)
            ref_slot = collection.get(slot.carrier)
          else
            ref_slot = collection.add(slot.carrier)
          end

          ref_slot.set(:model, slot)
          ref_slot.set(:share, slot.share)
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
          calculate_rubel_attribute(node, :demand)

          node.out_edges.each do |edge|
            calculate_rubel_attribute(edge, edge.get(:model).sets)
          end
        end

        Refinery::Reactor.new(
          Refinery::Catalyst::FromTurbine,
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
