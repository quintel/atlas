module Atlas
  class Scaler
    def initialize(base_dataset_key, derived_dataset_name, number_of_residences)
      @base_dataset         = Dataset::FullDataset.find(base_dataset_key)
      @derived_dataset_name = derived_dataset_name
      @number_of_residences = number_of_residences
    end

    def create_scaled_dataset
      derived_dataset = Dataset::DerivedDataset.new(@base_dataset.attributes.merge(attributes))
      derived_dataset.save!
      Scaler::GraphPersistor.new(@base_dataset, @derived_dataset_name).persist_graph
    end

    private

    def attributes
      {
        ns:             @derived_dataset_name,
        key:            @derived_dataset_name,
        area:           @derived_dataset_name,
        base_dataset:   @base_dataset.area,
        scaling:        scaling,
      }
    end

    def scaling
      {
        value:          @number_of_residences,
        base_value:     @base_dataset.number_of_residences,
        area_attribute: 'number_of_residences',
      }
    end
  end
end
