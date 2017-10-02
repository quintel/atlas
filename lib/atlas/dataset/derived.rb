module Atlas
  class Dataset::Derived < Dataset
    GRAPH_FILENAME             = 'graph.yml'.freeze
    INITIALIZER_INPUT_FILENAME = 'initializer_inputs.yml'.freeze
    VALID_INITIALIZER_INPUTS   = %w(
      preset_demand_setter
      max_demand_setter
      demand_setter
      share_setter
      conversion_setter
      reserved_fraction_setter
      number_of_units_setter
    ).freeze

    attribute :init,         Hash[Symbol => Float]
    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :geo_id,       String

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling
    validate :validate_presence_of_init_keys, if: -> { persisted? }
    validate :validate_presence_of_init_values, if: -> { persisted? }
    validate :validate_presence_of_graph_file

    validates_with SerializedGraphValidator

    validates_with WhitelistingInitializerMethods,
      attribute: :initializer_inputs, if: -> { persisted? }

    validates_with ShareGroupTotalValidator,
      attribute: :initializer_inputs, if: -> { persisted? }

    validates_with ShareGroupInclusionValidator,
      attribute: :initializer_inputs, if: -> { persisted? }

    def self.find_by_geo_id(geo_id)
      all.detect do |item|
        item.geo_id == geo_id
      end
    end

    def to_hash(*)
      if persisted?
        super.merge(initializer_inputs: initializer_inputs)
      else
        super
      end
    end

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      dataset_dir.join(GRAPH_FILENAME)
    end

    def initializer_inputs
      @initializer_inputs ||= YAML.load_file(initializer_input_path)
    end

    def initializer_input_path
      dataset_dir.join(INITIALIZER_INPUT_FILENAME)
    end

    private

    def validate_presence_of_base_dataset
      unless Dataset::Full.exists?(base_dataset)
        errors.add(:base_dataset, 'does not exist')
      end
    end

    def validate_scaling
      if scaling
        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end
    end

    def validate_presence_of_init_keys
      initializer_inputs.each_key do |key|
        unless VALID_INITIALIZER_INPUTS.include?(key)
          errors.add(:initializer_inputs, "'#{ key }' does not exist as an initializer input")
        end
      end
    end

    def validate_presence_of_init_values
      initializer_inputs.each_pair do |key, value|
        unless value.present?
          errors.add(:initializer_inputs, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end

    def validate_presence_of_graph_file
      if persisted? && !graph_path.file?
        errors.add(:graph, "graph.yml file is missing")
      end
    end
  end # Dataset::Derived
end # Atlas
