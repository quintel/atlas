module Atlas
  class Scaler::GraphScaler
    # All node attributes occurring in a graph.yml
    # created from nl dataset on 17-12-2016:
    # [:in, :out, :demand, :cc_out, :cc_in, :max_demand,
    #  :typical_input_capacity, :electricity_output_capacity]
    SCALED_NODE_ATTRIBUTES = [:demand,
                              :max_demand,
                              :typical_input_capacity,
                              :electricity_output_capacity].freeze

    def initialize(scaling_factor)
      @scaling_factor = scaling_factor
    end

    # Public: Scales the demands in the graph - modifying the original graph!
    #
    # graph - A Turbine::Graph containing nodes and edges.
    #
    # Returns the graph itself.
    def call(graph)
      graph[:nodes].each do |_, attributes|
        attributes.each do |key, value|
          if SCALED_NODE_ATTRIBUTES.include?(key) && value
            attributes[key] = @scaling_factor * value
          end
        end
      end
    end
  end # Scaler::GraphScaler
end # Atlas
