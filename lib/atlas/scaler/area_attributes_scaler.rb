module Atlas
  class Scaler::AreaAttributesScaler
    # Only attributes common to Full and Derived
    # may be scaled
    SCALEABLE_AREA_ATTRS = Atlas::Dataset.attribute_set
      .select { |attr| attr.options[:proportional] }.map(&:name).freeze

    def self.call(*args)
      new(*args).scale
    end

    private_class_method :new

    def initialize(base_dataset, scaling_factor)
      @base_dataset   = base_dataset
      @scaling_factor = scaling_factor
    end

    def scale
      result = {}
      SCALEABLE_AREA_ATTRS.map do |attr|
        if value = @base_dataset[attr]
          result[attr] = Util::round_computation_errors(value * @scaling_factor)
        end
      end
      result
    end
  end # Scaler::AreaAttributesScaler
end # Atlas
