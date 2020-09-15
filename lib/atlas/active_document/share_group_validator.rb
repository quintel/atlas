# frozen_string_literal: true

module Atlas
  module ActiveDocument
    class ShareGroupValidator < ActiveModel::Validator
      private

      def input_class
        options[:input_class]
      end

      def share_groups_for(record)
        values_attribute = (options[:share_attribute] || 'share').to_s

        record
          .public_send(options[:attribute])
          .each_with_object({}) do |(graph_key, methods), result|
            if graph_key =~ /-.+@/ && methods[values_attribute]
              edge = Edge.find(graph_key)
              group = group_key(edge)

              result[group] ||= {}
              result[group][graph_key] = methods[values_attribute]
            end

            result
          end
      end

      def expected_sum
        options[:sum] || 100.0
      end

      def group_key(edge)
        if options[:share_attribute] == :child_share
          edge.consumer
        else
          edge.supplier
        end
      end
    end
  end
end
