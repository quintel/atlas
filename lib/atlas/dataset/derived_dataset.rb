module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Hash

    validate :base_dataset_exists

    def graph
      YAML.load_file(File.join(directory, area, GRAPH))
    end

    # Overwrite
    def dataset_dir
      @dataset_dir ||=
        Atlas.data_dir.
          join(DIRECTORY).
          join(Dataset::FullDataset.find(base_dataset).key.to_s)
    end

    private

    def base_dataset_exists
      unless Dataset::FullDataset.exists?(base_dataset)
        errors.add(:base_dataset, 'does not exist')
      end
    end
  end # Dataset::DerivedDataset
end # Atlas
