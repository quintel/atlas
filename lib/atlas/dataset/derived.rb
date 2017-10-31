module Atlas
  class Dataset::Derived < Dataset
    GRAPH_FILENAME      = 'graph.yml'.freeze
    VALID_GRAPH_METHODS = %w(
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
    attribute :uses_deprecated_initializer_inputs, Boolean, default: false

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling
    validate :validate_presence_of_init_keys, if: -> { persisted? }
    validate :validate_presence_of_init_values, if: -> { persisted? }
    validate :validate_presence_of_graph_file

    validates_with SerializedGraphValidator

    validates_with WhitelistingInitializerMethods,
      attribute: :graph_values, if: -> { persisted? }

    validates_with ShareGroupTotalValidator,
      attribute: :graph_values, if: -> { persisted? }

    validates_with ShareGroupInclusionValidator,
      attribute: :graph_values, if: -> { persisted? }

    def self.find_by_geo_id(geo_id)
      all.detect do |item|
        item.geo_id == geo_id
      end
    end

    def to_hash(*)
      if persisted?
        super.merge(graph_values: graph_values)
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

    def graph_values
      @graph_values ||= GraphValues.new(self).read
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
      graph_values.each_key do |key|
        unless VALID_GRAPH_METHODS.include?(key)
          errors.add(:graph_values, "'#{ key }' does not exist as a graph method")
        end
      end
    end

    def validate_presence_of_init_values
      graph_values.each_pair do |key, value|
        unless value.present?
          errors.add(:graph_values, "value for graph method '#{ key }' can't be blank")
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
