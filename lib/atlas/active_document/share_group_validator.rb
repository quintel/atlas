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
          .each_with_object({}) do |(key, value), result|
            input = input_class.find(key)

            if input.share_group
              result[input.share_group] ||= {}
              result[input.share_group][input] = value
            end
          end
      end
    end
  end
end
