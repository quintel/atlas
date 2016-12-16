module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling

    validates :scaling, presence: true

    validate :base_dataset_exists
    validate :scaling_valid

    def graph
      @graph ||= GraphFromYaml.build(YAML.load_file(graph_path))
    end

    def graph_path
      File.join(directory, key.to_s, GRAPH_FILENAME)
    end

    # Overwrite
    def dataset_dir
      @dataset_dir ||= Atlas.data_dir.join(DIRECTORY, full_dataset.key.to_s)
    end

    def scaling_factor
      number_of_residences / full_dataset.number_of_residences
    end

    private

    def full_dataset
      Dataset::FullDataset.find(base_dataset)
    end

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
  end # Dataset::DerivedDataset
end # Atlas
