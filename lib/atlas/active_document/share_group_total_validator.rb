module Atlas
  module ActiveDocument
    class ShareGroupTotalValidator < ShareGroupValidator
      def validate(record)
        return if record.errors.messages[options[:attribute]]&.any?

        lower = expected_sum * 0.9999
        upper = expected_sum * 1.0001

        share_groups_for(record).each do |share_group, inputs|
          sum = inputs.values.sum

          next if sum.between?(lower, upper)

          record.errors.add(
            options[:attribute],
            "contains inputs belonging to the #{share_group} share group"\
            ", but the values sum to #{sum}, not #{expected_sum}"
          )
        end
      end
    end
  end
end
