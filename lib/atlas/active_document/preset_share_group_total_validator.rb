module Atlas
  module ActiveDocument
    class PresetShareGroupTotalValidator < ShareGroupTotalValidator
      private

      def share_groups_for(record)
        record.user_values.each_with_object({}) do |(key, value), result|
          input = Input.find(key)

          if input.share_group
            result[input.share_group] ||= {}
            result[input.share_group][input] = value
          end
        end
      end
    end
  end
end
