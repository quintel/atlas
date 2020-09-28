module Atlas
  # Acts as a controller for building the fully-calculated graph.
  #
  # Loads the graph structure and attributes from the source files, calculates
  # the Rubel-based attributes, triggers the Refinery calculations, and
  # returns to results to you.
  class Runner
    attr_reader :dataset

    # Queries must return a numeric value, or one of these.
    PERMITTED_NON_NUMERICS = [nil, :infinity, :recursive].freeze

    # Public: Creates a new Runner.
    #
    # Returns a Runner.
    def initialize(dataset)
      @dataset = dataset
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate(with = Refinery::Catalyst::Calculators)
      refinery_catalysts = [*precursors, with, Refinery::Catalyst::Validation]

      refinery_catalysts.compact.reduce(refinery_graph) do |result, catalyst|
        catalyst.call(result)
      end
    end

    # Public: Returns the Refinery graph which the Runner uses to calculate
    # missing attributes.
    #
    # Returns a Turbine::Graph.
    def refinery_graph
      @refinery ||= begin
        catalysts.reduce(graph) do |result, catalyst|
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

    def graph
      @graph ||= GraphBuilder.build
    end

    private

    def precursors
      return unless precomputed_graph? && !@dataset.uses_deprecated_initializer_inputs

      [SetAttributesFromGraphValues.with_dataset(@dataset), ZeroMoleculeNodes]
    end

    def catalysts
      [
        SetRubelAttributes.with_queryable(method(:query)),
        SetSlotSharesFromEfficiency.with_queryable(method(:query)),
        ScaleAttributes.with_dataset(dataset),
        ZeroDisabledSectors.with_dataset(dataset),
        ZeroMoleculeLeaves
      ]
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
      dataset.is_a?(Dataset::Derived)
    end
  end
end
