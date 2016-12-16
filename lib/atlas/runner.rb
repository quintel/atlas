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
      @graph   = graph || dataset.graph
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate
      catalysts_for_refinery_graph(:calculate)
        .reduce(refinery_graph) do |result, catalyst|
          catalyst.call(result)
        end
    end

    # Public: Returns the Refinery graph which the Runner uses to calculate
    # missing attributes.
    #
    # Returns a Turbine::Graph.
    def refinery_graph(which = refinery_scope)
      @refinery ||= begin
        catalysts_for_refinery_graph(which).reduce(graph) do |result, catalyst|
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
      dataset.is_a?(Dataset::DerivedDataset) ? :import : :all
    end

    def catalysts_for_refinery_graph(which)
      catalysts.select { |_, scopes| scopes.include?(which) }.keys
    end

    def catalysts
      {
        SetRubelAttributes.with_queryable(method(:query)) =>
          [:export, :all],
        Refinery::Catalyst::FromTurbine =>
          [:import, :export, :all],
        SetSlotSharesFromEfficiency.with_queryable(method(:query)) =>
          [:import, :export, :all],
        ZeroDisabledSectors.with_dataset(dataset) =>
          [:import, :all],
        Refinery::Catalyst::Calculators =>
          [:calculate],
        Refinery::Catalyst::Validation =>
          [:calculate]
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

  end # Runner
end # Atlas
