module Atlas
  module ActiveDocument
    class ShareGroupInclusionValidator < ShareGroupValidator
      def validate(record)
        return if record.errors.messages[options[:attribute]]

        inputs = input_class.by_share_group

        share_groups_for(record).each_pair do |share_group, inputs|
          missing = inputs[share_group] - inputs.keys

          if missing && missing.any?
            record.errors.add(
              options[:attribute],
              "share group '#{ share_group }' is missing the "\
              "following share(s): #{ missing.map(&:key).join(', ') }"
            )
          end
        end
      end
    end
  end
end
