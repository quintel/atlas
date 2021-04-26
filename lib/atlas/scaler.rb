module Atlas
  class Scaler
    LINKED_FILES = %w[
      carriers.csv
      curves
      demands
      fce
      load_profiles
      network
      real_estate
    ].freeze

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
      symlink_etengine_data_files
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

    def symlink_etengine_data_files
      LINKED_FILES.each do |folder|
        base = @base_dataset.dataset_dir.join(folder)

        next unless base.exist?

        FileUtils.ln_s(
          base.relative_path_from(@derived_dataset.dataset_dir),
          @derived_dataset.dataset_dir
        )
      end
    end

    def create_empty_graph_values_file
      GraphValues.new(@derived_dataset).create!
    end
  end
end
