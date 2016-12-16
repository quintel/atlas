module Atlas
  class Runner
    class SetRubelAttributes
      def self.with_queryable(query)
        lambda do |graph|
          graph.nodes.each do |node|
            calculate_rubel_attributes!(node, query)

            node.out_edges.each do |edge|
              calculate_rubel_attributes!(edge, query)
            end
          end

          graph
        end
      end

      private

      # ActiveDocument.
      def self.calculate_rubel_attributes!(element, query)
        model = element.get(:model)

        model.queries && model.queries.each do |attribute, rubel_string|
          # Skip slot shares.
          unless attribute.match(/^(?:in|out)put\./)
            element.set(attribute, query.call(rubel_string))
          end
        end
      end
    end
  end
end
