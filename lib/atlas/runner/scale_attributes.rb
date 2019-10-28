# frozen_string_literal: true

module Atlas
  class Runner
    module ScaleAttributes
      module_function

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

      SCALED_ATTRIBUTES = {
        edges: EDGE_ATTRIBUTES,
        nodes: NODE_ATTRIBUTES
      }.freeze

      def scale!(obj, scaling_factor)
        scope =
          case obj
          when Refinery::Node then :nodes
          when Refinery::Edge then :edges
          end

        obj.properties
          .slice(*SCALED_ATTRIBUTES[scope])
          .each_pair do |attr, val|
            next unless val

            obj.set(attr, val * scaling_factor)
          end
      end

      # Public: Scales the demands in the graph hash - modifying the original hash!
      #
      # graph - A Hash containing nodes and edges.
      #
      # Returns the modified graph hash itself.
      def with_dataset(dataset)
        lambda do |graph|
          if dataset.is_a?(Dataset::Derived)
            scaling_factor = dataset.scaling.factor

            graph.nodes.each do |node|
              next if node.get(:model).scaling_exempt

              scale!(node, scaling_factor)

              node.out_edges.each { |edge| scale!(edge, scaling_factor) }
            end
          end

          graph
        end
      end
    end
  end
end
