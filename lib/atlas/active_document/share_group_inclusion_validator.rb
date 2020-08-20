module Atlas
  module ActiveDocument
    class ShareGroupInclusionValidator < ShareGroupValidator
      def validate(record)
        return if record.errors.messages[options[:attribute]]&.any?

        share_groups_for(record).each_pair do |share_group, inputs|
          missing = share_inputs[share_group] - inputs.keys

          if missing && missing.any?
            record.errors.add(
              options[:attribute],
              "share group '#{ share_group }' is missing the "\
              "following share(s): #{ missing.join(', ') }"
            )
          end
        end
      end

      private

      def share_inputs
        @share_inputs ||= Edge.all.each_with_object({}) do |edge, hash|
          hash[edge.supplier] ||= []
          hash[edge.supplier] << edge.key
          hash
        end
      end
    end
  end
end
