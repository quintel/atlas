module Atlas
  class ShareGroupValidator < ActiveModel::Validator
    def validate(record)
      @record = record

      unless @record.errors.messages[options[:attribute]]
        share_groups_exist
        share_groups_sum
      end
    end

    private

    def inputs
      @record.public_send(options[:attribute])
    end

    def input_class
      options[:input_class]
    end

    def share_groups
      inputs.each_with_object({}) do |(key, value), result|
        input = input_class.find(key)

        if input.share_group
          result[input.share_group] ||= {}
          result[input.share_group][input] = value
        end
      end
    end

    def share_groups_exist
      share_groups.each_pair do |share_group, inputs|
        missing = input_class.by_share_group[share_group] - inputs.keys

        if missing && missing.any?
          @record.errors.add(
            options[:attribute],
            "share group '#{ share_group }' is missing the "\
            "following share(s): #{ missing.map(&:key).join(', ') }"
          )
        end
      end
    end

    # Internal: Asserts that any input keys which belong to a share group
    # specify values which sum to 100.
    #
    # Returns nothing.
    def share_groups_sum
      share_groups.each do |share_group, inputs|
        unless inputs.values.sum.between?(99.99, 100.01)
          @record.errors.add(
            options[:attribute],
            "contains inputs belonging to the #{ share_group } share group"\
            ", but the values sum to #{ inputs.values.sum }, not 100"
          )
        end
      end
    end
  end
end
