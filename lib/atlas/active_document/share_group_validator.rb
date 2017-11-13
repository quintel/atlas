module Atlas
  module ActiveDocument
    class ShareGroupValidator < ActiveModel::Validator
      private

      def input_class
        options[:input_class]
      end

      # The 'share group' of an edge in the case of initializer inputs
      # will always be the name of the supplier.
      def share_groups_for(record)
        record
          .public_send(options[:attribute])
          .each_with_object({}) do |(key, elements), result|
            elements.each_pair do |graph_key, value|
              if graph_key =~ /-/
                edge = Edge.find(graph_key)

                result[edge.supplier] ||= {}
                result[edge.supplier][graph_key] = value
              end
            end

            result
          end
      end
    end
  end
end
