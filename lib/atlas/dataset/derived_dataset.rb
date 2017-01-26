module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :init,         Hash[Symbol => Float]

    validates :scaling, presence: true
    validates :base_dataset, presence: true

    validate :base_dataset_exists
    validate :scaling_valid
    validate :init_keys_exist
    validate :init_values_present

    validates_with ShareGroupTotalValidator,
      attribute: :init, input_class: InitializerInput

    validates_with ShareGroupInclusionValidator,
      attribute: :init, input_class: InitializerInput

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      File.join(directory, key.to_s, GRAPH_FILENAME)
    end

    private

    def base_dataset_exists
      unless Dataset::FullDataset.exists?(base_dataset)
        errors.add(:base_dataset, 'does not exist')
      end
    end

    def scaling_valid
      if scaling
        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end
    end

    def init_keys_exist
      init.each_key do |key|
        unless InitializerInput.exists?(key)
          errors.add(:init, "'#{ key }' does not exist as an initializer input")
        end
      end
    end

    def init_values_present
      init.each_pair do |key, value|
        unless value.present?
          errors.add(:init, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end
  end # Dataset::DerivedDataset
end # Atlas
