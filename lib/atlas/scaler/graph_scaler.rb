module Atlas
  class Scaler::GraphScaler
    # Edge attributes which must be scaled.
    EDGE_ATTRIBUTES = [:demand].freeze

    # Node attributes which must be scaled.
    NODE_ATTRIBUTES = [
      :demand,
      :max_demand,
      :number_of_units
      # Scaling of the following two attributes is disabled for the time being -
      # see https://github.com/quintel/etengine/issues/901#issuecomment-274062242
      # :typical_input_capacity,
      # :electricity_output_capacity
    ].freeze

    def initialize(scaling_factor)
      @scaling_factor = scaling_factor
    end

    # Public: Scales the demands in the graph hash - modifying the original hash!
    #
    # graph - A Hash containing nodes and edges.
    #
    # Returns the modified graph hash itself.
    def call(graph)
      graph.nodes.each do |node|
        scale_node!(node)
        node.edges(:out).each { |edge| scale_object!(edge, EDGE_ATTRIBUTES) }
      end

      graph
    end

    private

    # Internal: Scales attributes of a node, unless the `scaling_exempt` flag is
    # set.
    #
    # Returns nothing.
    def scale_node!(node)
      unless node.get(:model).scaling_exempt
        scale_object!(node, NODE_ATTRIBUTES)
      end
    end

    # Internal: Scales the `attributes` of the `object`.
    #
    # Returns nothing.
    def scale_object!(object, attributes)
      attributes.each do |attribute|
        if (value = object.get(attribute))
          object.set(attribute, value * @scaling_factor)
        end
      end
    end
  end # Scaler::GraphScaler
end # Atlas
