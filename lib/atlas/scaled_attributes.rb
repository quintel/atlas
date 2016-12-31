module Atlas
  class Scaler::ScaledAttributes
    # Only attributes common to FullDataset and DerivedDataset
    # may be scaled
    SCALEABLE_AREA_ATTRS = Atlas::Dataset.attribute_set
      .select { |attr| attr.options[:proportional] }.map(&:name).freeze

    def initialize(dataset, number_of_residences)
      @dataset              = dataset
      @number_of_residences = number_of_residences
    end

    def scale
      Hash[
        SCALEABLE_AREA_ATTRS.map do |attr|
          if value = @dataset[attr]
            [attr, Util::round_computation_errors(value * scaling_factor)]
          end
        end.compact
      ]
    end

    private

    def scaling_factor
      value.to_f / base_value
    end

    def base_value
      @dataset.number_of_residences
    end

    def value
      @number_of_residences
    end
  end
end
