module Atlas
  class Scaler::GraphScaler
    # Edge attributes which must be scaled.
    EDGE_ATTRIBUTES = [:demand].freeze

    # Node attributes which must be scaled.
    NODE_ATTRIBUTES = [
      :demand,
      :max_demand,
      :typical_input_capacity,
      :electricity_output_capacity
    ].freeze

    # Maps top-level keys from the dumped graph to arrays of attributes which
    # need to be scaled.
    SCALED_ATTRIBUTES = {
      edges: EDGE_ATTRIBUTES,
      nodes: NODE_ATTRIBUTES
    }.freeze

    def initialize(scaling_factor)
      @scaling_factor = scaling_factor
    end

    # Public: Scales the demands in the graph hash - modifying the original hash!
    #
    # graph - A Hash containing nodes and edges.
    #
    # Returns the modified graph hash itself.
    def call(graph)
      SCALED_ATTRIBUTES.each do |graph_key, attributes|
        graph[graph_key].each_value do |record|
          attributes.each do |attr|
            record[attr] = @scaling_factor * record[attr] if record[attr]
          end
        end
      end
      graph
    end
  end # Scaler::GraphScaler
end # Atlas
