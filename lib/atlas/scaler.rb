module Atlas
  class Scaler
    def initialize(dataset, local_dataset_name, number_of_residences)
      @dataset              = Dataset.find(dataset)
      @local_dataset_name   = local_dataset_name
      @number_of_residences = number_of_residences
    end

    def create_scaled_dataset
      LocalDataset.new(attributes).save
      Scaler::GraphPersistor.new(@dataset, @local_dataset_name).persist_graph
    end

    private

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
