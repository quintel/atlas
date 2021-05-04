module Atlas
  class Scaler
    def initialize(base_dataset_key, derived_dataset_name, number_of_residences, base_value = nil, time_curves_to_zero: false)
      @base_dataset         = Dataset::Full.find(base_dataset_key)
      @derived_dataset_name = derived_dataset_name
      @number_of_residences = number_of_residences
      @base_value           = base_value || @base_dataset.number_of_residences
      @time_curves_to_zero  = time_curves_to_zero
    end

    def create_scaled_dataset
      @derived_dataset = Dataset::Derived.new(attributes)
      @derived_dataset.attributes =
        AreaAttributesScaler.call(@base_dataset, @derived_dataset.scaling.factor)
      @derived_dataset.save!

      TimeCurveScaler.call(@base_dataset, @derived_dataset, @time_curves_to_zero)

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
          value:          @number_of_residences,
          base_value:     @base_value,
          area_attribute: 'number_of_residences'
        }
      }
    end

    def create_empty_graph_values_file
      GraphValues.new(@derived_dataset).create!
    end
  end
end
