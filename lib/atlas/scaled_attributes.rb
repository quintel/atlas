module Atlas
  class Scaler::ScaledAttributes
    def initialize(dataset, number_of_residences)
      @dataset              = dataset
      @number_of_residences = number_of_residences
    end

    def scale
      Hash[proportional_attributes.map do |attr|
        [attr.name.to_s, @dataset.send(attr.name) / scaling_factor]
      end]
    end

    private

    def scaling_factor
      base_value / value
    end

    def base_value
      @dataset.number_of_residences
    end

    def value
      @number_of_residences.to_f
    end

    def proportional_attributes
      @dataset.send(:attribute_set).select do |attr|
        attr.options[:proportional] && @dataset.send(attr.name)
      end
    end
  end
end
