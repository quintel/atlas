module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling

    validates :scaling, presence: true

    validate :base_dataset_exists
    validate :scaling_valid

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      File.join(directory, key.to_s, GRAPH_FILENAME)
    end

    # Overwrite
    def dataset_dir
      @dataset_dir ||= Atlas.data_dir.join(DIRECTORY, base_dataset)
    end

    def time_curves_dir
      Atlas.data_dir.
        join(DIRECTORY).
        join(key.to_s).
        join('time_curves')
    end

    def time_curve_path(key)
      time_curves_dir.join("#{ key }_time_curve.csv")
    end

    # Public: Retrieves the time curve data for the file whose name matches
    # +key+.
    #
    # Overwrite
    #
    # key - The name of the time curve file to load.
    #
    # For example:
    #   dataset.time_curve(woody_biomass).get(2011, :max_demand) # => 34.0
    #
    # Returns a CSVDocument.
    def time_curve(key)
      (@time_curves ||= {})[key.to_sym] ||=
        CSVDocument.new(time_curve_path(key))
    end

    # Public: Retrieves all the time curves for the dataset's region.
    #
    # Overwrite
    #
    # Returns a hash of document keys, and the CSVDocuments.
    def time_curves
      Pathname.glob(time_curves_dir.join('*.csv')).each do |csv_path|
        time_curve(csv_path.basename('_time_curve.csv').to_s)
      end

      @time_curves ||= {}
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
  end # Dataset::DerivedDataset
end # Atlas
