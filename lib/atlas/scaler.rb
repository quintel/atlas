module Atlas
  class Scaler
    def initialize(dataset, local_dataset_name, number_of_residences)
      @dataset              = Dataset.find(dataset)
      @local_dataset_name   = local_dataset_name
      @number_of_residences = number_of_residences
    end

    def create_scaled_dataset
      create_local_dataset
      persist_current_graph
    end

    private

    def create_local_dataset
      LocalDataset.new(attributes).save
    end

    def persist_current_graph
      # Dump this as a yaml file
      Runner.new(@dataset, graph).calculate
    end

    def graph
      GraphBuilder.build
    end

    def attributes
      {
        'key'     => @local_dataset_name,
        'name'    => @local_dataset_name,
        'path'    => path,
        'scaling' => scaling
      }
    end

    def scaling
      {
        'value'          => @number_of_residences,
        'base_value'     => @dataset.number_of_residences,
        'area_attribute' => 'number_of_residences'
      }
    end

    def path
      "#{ @local_dataset_name }/#{ @local_dataset_name }"
    end
  end
end
