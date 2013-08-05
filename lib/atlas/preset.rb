module Atlas
  # Presets are saved scenarios whose results we want to make available in the
  # ETModel front-end.
  class Preset
    include ActiveDocument

    DIRECTORY = 'presets'

    attribute :id,                 Integer
    attribute :description,        String
    attribute :ordering,           Integer
    attribute :author,             String
    attribute :title,              String
    attribute :comments,           String
    attribute :created_at,         Time
    attribute :updated_at,         Time
    attribute :end_year,           Integer
    attribute :in_start_menu,      Boolean
    attribute :user_id,            Integer
    attribute :use_fce,            Boolean
    attribute :present_updated_at, Time
    attribute :protected,          Boolean
    attribute :area_code,          String
    attribute :user_values,        Hash[Symbol => Float]

    validates :title,       presence: true
    validates :area_code,   presence: true
    validates :end_year,    presence: true
    validates :user_values, presence: true

    validate  :validate_input_keys, if: ->{ user_values && user_values.any? }

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
  end # Preset
end # Atlas
