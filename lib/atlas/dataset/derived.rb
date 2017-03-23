module Atlas
  class Dataset::Derived < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :init,         Hash[Symbol => Float]

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling
    validate :validate_presence_of_init_keys
    validate :validate_presence_of_init_values

    validates_with ShareGroupTotalValidator,
      attribute: :init, input_class: InitializerInput

    validates_with ShareGroupInclusionValidator,
      attribute: :init, input_class: InitializerInput

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      dataset_dir.join(GRAPH_FILENAME)
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
      init.each_key do |key|
        unless InitializerInput.exists?(key)
          errors.add(:init, "'#{ key }' does not exist as an initializer input")
        end
      end
    end

    def validate_presence_of_init_values
      init.each_pair do |key, value|
        unless value.present?
          errors.add(:init, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end
  end # Dataset::Derived
end # Atlas
