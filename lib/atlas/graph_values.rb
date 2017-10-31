module Atlas
  class GraphValues
    GRAPH_VALUES_FILENAME = 'graph_values.yml'.freeze

    def initialize(derived_dataset)
      @derived_dataset = derived_dataset
    end

    def read
      YAML.load_file(graph_values_path)
    end

    def create
      File.write(graph_values_path, "--- {}")
    end

    private

    def graph_values_path
      @derived_dataset.dataset_dir.
        join(GRAPH_VALUES_FILENAME)
    end
  end
end
