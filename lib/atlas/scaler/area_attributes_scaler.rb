module Atlas
  class Scaler::AreaAttributesScaler
    # Only attributes common to FullDataset and DerivedDataset
    # may be scaled
    SCALEABLE_AREA_ATTRS = Atlas::Dataset.attribute_set
      .select { |attr| attr.options[:proportional] }.map(&:name).freeze

    def self.call(*args)
      new(*args).scale
    end

    def initialize(base_dataset, scaling_factor)
      @base_dataset   = base_dataset
      @scaling_factor = scaling_factor
    end

    def scale
      Hash[
        SCALEABLE_AREA_ATTRS.map do |attr|
          if value = @base_dataset[attr]
            [attr, Util::round_computation_errors(value * @scaling_factor)]
          end
        end.compact
      ]
    end
  end # Scaler::AreaAttributesScaler
end # Atlas
