module Atlas
  class Scaler
    UNSCALED_ETENGINE_DATA_FILES = %w( fce load_profiles network ).freeze

    def initialize(base_dataset_key, derived_dataset_name, number_of_residences, base_value = nil)
      @base_dataset         = Dataset::Full.find(base_dataset_key)
      @derived_dataset_name = derived_dataset_name
      @number_of_residences = number_of_residences
      @base_value           = base_value
    end

    def create_scaled_dataset
      @derived_dataset = Dataset::Derived.new(
        @base_dataset.attributes.
          merge(AreaAttributesScaler.call(@base_dataset, scaling_factor)).
          merge(new_attributes))

      @derived_dataset.save!

      GraphPersistor.call(
        @base_dataset,
        @derived_dataset.graph_path,
        export_modifier: Scaler::GraphScaler.new(scaling_factor))

      TimeCurveScaler.call(@base_dataset, scaling_factor, @derived_dataset)

      copy_etengine_data_files
    end

    private

    def value
      @number_of_residences
    end

    def base_value
      @base_value || @base_dataset.number_of_residences
    end

    def scaling_factor
      value.to_r / base_value.to_r
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
        scaling: {
          value:          value,
          base_value:     base_value,
          area_attribute: 'number_of_residences'
        }
      }
    end

    def copy_etengine_data_files
      FileUtils.cp_r(
        UNSCALED_ETENGINE_DATA_FILES.
          map { |subdir| File.join(@base_dataset.dataset_dir, subdir) },
        @derived_dataset.dataset_dir)
    end
  end # Scaler
end # Atlas
