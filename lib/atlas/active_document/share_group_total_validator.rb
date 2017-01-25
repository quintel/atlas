module Atlas
  module ActiveDocument
    class ShareGroupTotalValidator < ShareGroupValidator
      def validate(record)
        return if record.errors.messages[options[:attribute]]

        share_groups_for(record).each do |share_group, inputs|
          unless inputs.values.sum.between?(99.99, 100.01)
            record.errors.add(
              options[:attribute],
              "contains inputs belonging to the #{ share_group } share group"\
              ", but the values sum to #{ inputs.values.sum }, not 100"
            )
          end
        end
      end
    end
  end
end
