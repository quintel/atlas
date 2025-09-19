module Atlas
  class Scaler
    def initialize(base_dataset_key, derived_dataset_name, number_of_inhabitants, base_value = nil)
      @base_dataset         = Dataset.find(base_dataset_key)
      @derived_dataset_name = derived_dataset_name
      @number_of_inhabitants = number_of_inhabitants
      @base_value           = base_value || @base_dataset.number_of_inhabitants
    end

    def create_scaled_dataset
      @derived_dataset = Dataset::Derived.new(attributes)

      unless @derived_dataset.scaling && @derived_dataset.scaling.valid?
        @derived_dataset.valid?
        raise InvalidDocumentError.new(@derived_dataset)
      end
      scaled_attrs = AreaAttributesScaler.call(@base_dataset, @derived_dataset.scaling.factor)
      # Overwrite proportional attributes with their scaled values.
      scaled_attrs.each { |k, v| @derived_dataset[k] = v }
      @derived_dataset.save!

      create_empty_graph_values_file
    end

    private

    def attributes
      @base_dataset.attributes.merge(new_attributes)
    end

    def new_attributes
      id = Dataset.all.map(&:id).max + 1
      {
        id:             id,
        parent_id:      id,
        ns:             @derived_dataset_name,
        key:            @derived_dataset_name,
        area:           @derived_dataset_name,
        base_dataset:   @base_dataset.area,
        enabled: {
          etmodel:      true,
          etengine:     true
        },
        scaling: {
          value:          @number_of_inhabitants,
          base_value:     @base_value,
          area_attribute: 'number_of_inhabitants'
        }
      }
    end

    def create_empty_graph_values_file
      GraphValues.new(@derived_dataset).create!
    end
  end
end
