module Atlas
  # Presets are saved scenarios whose results we want to make available in the
  # ETModel front-end.
  class Preset
    include ActiveDocument

    attribute :id,                 Integer
    attribute :description,        String
    attribute :ordering,           Integer
    attribute :title,              String
    attribute :display_group,      String
    attribute :end_year,           Integer
    attribute :in_start_menu,      Boolean
    attribute :area_code,          String
    attribute :user_values,        Hash[Symbol => Float]
    attribute :scaling,            Scaling
    attribute :flexibility_order,  Array[String]
    attribute :heat_network_order, Array[String]

    validates :title,       presence: true
    validates :area_code,   presence: true
    validates :end_year,    presence: true
    validates :user_values, presence: true

    validate  :validate_input_keys,   if: -> { user_values && user_values.any? }
    validate  :validate_scaling,      if: -> { scaling }

    validates_with PresetShareGroupTotalValidator,
      attribute: :user_values,
      if: -> { user_values && user_values.any? }

    validates_with UserSortableValidator,
      attribute: :flexibility_order,
      if: -> { flexibility_order&.any? },
      in: -> { Array(Atlas::Config.read?('flexibility_order')) }

    validates_with UserSortableValidator,
      attribute: :heat_network_order,
      if: -> { heat_network_order&.any? },
      in: -> { Array(Atlas::Config.read?('heat_network_order')) }

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
          "#{ intersection.sort.inspect }"
        )
      end
    end

    def validate_scaling
      return if scaling.valid?

      scaling.errors.each do |key, messages|
        errors.add("scaling.#{ key }", messages)
      end
    end
  end
end
