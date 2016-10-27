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
    def initialize(dataset, graph)
      @dataset = dataset
      @graph   = graph
    end

    # Public: Calculates the graph.
    #
    # I feel like this should be a separate class, but for the sake of
    # temporary simplicity, I'm going to put it in a method.
    #
    # Returns the calculated Graph.
    def calculate(with = Refinery::Catalyst::Calculators)
      catalysts = [with, Refinery::Catalyst::Validation]

      catalysts.reduce(refinery_graph) do |result, catalyst|
        catalyst.call(result)
      end
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

        catalysts = [
          Refinery::Catalyst::FromTurbine,
          ZeroDisabledSectors.with_dataset(dataset),
          SetSlotSharesFromEfficiency.with_queryable(method(:query))
        ]

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

    #######
    private
    #######

    # Internal: Given an +element+ from the graph -- a node or edge --
    # calculate any Rubel queries which are defined on the associated
    # ActiveDocument.
    def calculate_rubel_attributes!(element)
      model = element.get(:model)

      model.queries && model.queries.each do |attribute, rubel_string|
        # Skip slot shares.
        unless attribute.match(/^(?:in|out)put\./)
          element.set(attribute, query(rubel_string))
        end
      end
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
