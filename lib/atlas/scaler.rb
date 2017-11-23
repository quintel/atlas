module Atlas
  class Scaler
    UNSCALED_ETENGINE_DATA_FILES = %w( fce load_profiles network ).freeze

    def initialize(base_dataset_key, derived_dataset_name, number_of_residences, base_value = nil)
      @base_dataset         = Dataset::Full.find(base_dataset_key)
      @derived_dataset_name = derived_dataset_name
      @number_of_residences = number_of_residences
      @base_value           = base_value || @base_dataset.number_of_residences
    end

    def create_scaled_dataset
      @derived_dataset = Dataset::Derived.new(attributes)
      @derived_dataset.attributes =
        AreaAttributesScaler.call(@base_dataset, @derived_dataset.scaling.factor)
      @derived_dataset.save!

      GraphPersistor.call(
        @base_dataset,
        @derived_dataset.graph_path,
        export_modifier: Scaler::GraphScaler.new(@derived_dataset.scaling.factor))

      TimeCurveScaler.call(@base_dataset, @derived_dataset)

      create_empty_graph_values_file
      copy_etengine_data_files
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
        scaling: {
          value:          @number_of_residences,
          base_value:     @base_value,
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

    def create_empty_graph_values_file
      GraphValues.new(@derived_dataset).create!
    end
  end # Scaler
end # Atlas
