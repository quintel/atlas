module Atlas
  # Acts as a controller for building the fully-calculated graph.
  #
  # Loads the graph structure and attributes from the source files, calculates
  # the Rubel-based attributes, triggers the Refinery calculations, and
  # returns to results to you.
  class Runner
    attr_reader :dataset, :graph

    # Queries must return a numeric value, or one of these.
    PERMITTED_NON_NUMERICS = [nil, :infinity, :recursive].freeze

    # Public: Creates a new Runner.
    #
    # Returns a Runner.
    def initialize(dataset, graph = nil)
      @dataset = dataset
      @graph   = set_graph(graph)
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate(with = Refinery::Catalyst::Calculators)
      refinery_catalysts = [with, Refinery::Catalyst::Validation]

      refinery_catalysts.reduce(refinery_graph) do |result, catalyst|
        catalyst.call(result)
      end
    end

    # Public: Returns the Refinery graph which the Runner uses to calculate
    # missing attributes.
    #
    # Returns a Turbine::Graph.
    def refinery_graph(which = refinery_scope)
      @refinery ||= begin
        catalysts(which).reduce(graph) do |result, catalyst|
          catalyst.call(result)
        end
      end
    end

    # Public: The runtime used by the Runner to calculate Rubel attributes.
    #
    # Returns an Atlas::Runtime.
    def runtime
      @runtime ||= Runtime.new(dataset, graph)
    end

    private

    def refinery_scope
      precomputed_graph? ? :import : :all
    end

    def catalysts(which)
      if which == :all
        transformations.values.flatten
      else
        transformations.fetch(which)
      end
    end

    def transformations
      {
        export: [
          SetRubelAttributes.with_queryable(method(:query)),
          SetSlotSharesFromEfficiency.with_queryable(method(:query))
        ],
        import: [
          ZeroDisabledSectors.with_dataset(dataset)
        ]
      }
    end

    # Internal: Executes the given Rubel query +string+, returning the
    # result.
    def query(string)
      result = runtime.execute(string)

      unless result.is_a?(Numeric) || PERMITTED_NON_NUMERICS.include?(result)
        fail NonNumericQueryError.new(result)
      end

      result == :infinity ? Float::INFINITY : result
    rescue RuntimeError => ex
      ex.message.gsub!(/$/, " (executing: #{ string.inspect })")
      raise ex
    end

    def precomputed_graph?
      dataset.is_a?(Dataset::DerivedDataset)
    end

    def set_graph(graph)
      if graph.is_a?(Turbine::Graph)
        graph
      elsif precomputed_graph?
        dataset.graph
      else
        GraphBuilder.build
      end
    end
  end # Runner
end # Atlas
