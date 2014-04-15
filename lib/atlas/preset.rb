module Atlas
  # Presets are saved scenarios whose results we want to make available in the
  # ETModel front-end.
  class Preset
    include ActiveDocument

    DIRECTORY = 'presets'

    attribute :id,                 Integer
    attribute :description,        String
    attribute :ordering,           Integer
    attribute :title,              String
    attribute :display_group,      String
    attribute :end_year,           Integer
    attribute :in_start_menu,      Boolean
    attribute :use_fce,            Boolean
    attribute :area_code,          String
    attribute :user_values,        Hash[Symbol => Float]

    validates :title,       presence: true
    validates :area_code,   presence: true
    validates :end_year,    presence: true
    validates :user_values, presence: true

    validate  :validate_input_keys,   if: ->{ user_values && user_values.any? }
    validate  :validate_share_groups, if: ->{ user_values && user_values.any? }

    #######
    private
    #######

    # Internal: Validation which asserts that the input keys contained in the
    # user values hash each reference an input which exists.
    #
    # Returns nothing.
    def validate_input_keys
      input_keys   = Input.all.map(&:key)
      preset_keys  = user_values.keys

      if (intersection = preset_keys - input_keys).any?
        errors.add(:user_values,
                   "contains input keys which don't exist: " \
                   "#{ intersection.sort.inspect }")
      end
    end

    # Internal: Asserts that any input keys which belong to a share group
    # specify values which sum to 100.
    #
    # Returns nothing.
    def validate_share_groups
      unvalidated_inputs = user_values.keys

      Input.by_share_group.each do |key, inputs|
        group_keys = inputs.map(&:key)

        if (unvalidated_inputs & group_keys).any?
          sum = group_keys.sum { |key| user_values[key] }

          unless sum.between?(99.9, 100.1)
            errors.add(:user_values,
                       "contains inputs belonging to the #{ key } share " \
                       "group, but the values sum to #{ sum }, not 100")
          end
        end
      end
    end

  end # Preset
end # Atlas
