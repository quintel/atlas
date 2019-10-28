# frozen_string_literal: true

module Atlas
  module ActiveDocument
    class ShareGroupValidator < ActiveModel::Validator
      private

      def input_class
        options[:input_class]
      end

      def share_groups_for(record)
        record
          .public_send(options[:attribute])
          .each_with_object({}) do |(graph_key, methods), result|
            if graph_key =~ /-.+@/
              edge = Edge.find(graph_key)

              result[edge.supplier] ||= {}
              result[edge.supplier][graph_key] = methods['share']
            end

            result
          end
      end
    end
  end
end
