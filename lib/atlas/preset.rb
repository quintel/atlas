# frozen_string_literal: true

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
    attribute :scaling,            Scaling
    attribute :flexibility_order,  Array[Symbol]

    validates :title,       presence: true
    validates :area_code,   presence: true
    validates :end_year,    presence: true
    validates :user_values, presence: true

    validate  :validate_input_keys,   if: -> { user_values && user_values.any? }
    validate  :validate_scaling,      if: -> { scaling }

    validates_with PresetShareGroupTotalValidator,
      attribute: :user_values,
      if: -> { user_values && user_values.any? }

    private

    # Internal: Validation which asserts that the input keys contained in the
    # user values hash each reference an input which exists.
    #
    # Returns nothing.
    def validate_input_keys
      input_keys   = Input.all.map(&:key)
      preset_keys  = user_values.keys

      if (intersection = preset_keys - input_keys).any?
        errors.add(
          :user_values,
          "contains input keys which don't exist: " \
          "#{intersection.sort.inspect}"
        )
      end
    end

    def validate_scaling
      return if scaling.valid?

      scaling.errors.each do |key, messages|
        errors.add("scaling.#{key}", messages)
      end
    end
  end
end
