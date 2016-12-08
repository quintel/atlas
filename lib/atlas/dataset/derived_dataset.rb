module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH     = 'graph.yml'.freeze

    attribute :base_dataset,      String
    attribute :scaling,           Hash

    validate :base_dataset_exists

    def graph
      YAML.load_file(File.join(directory, area, GRAPH))
    end

    #######
    private
    #######

    def base_dataset_exists
      errors.add(:base_dataset, "does not exist") unless Dataset::FullDataset.exists? base_dataset
    end
  end # Dataset::DerivedDataset
end # Atlas
