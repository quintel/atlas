module Atlas
  class Preset
    # Describes scenarios which are to be scaled down to a smaller region size.
    class Scaling
      include ValueObject
      include ActiveModel::Validations

      values do
        attribute :area_attribute,  String
        attribute :value,           Integer
        attribute :base_value,      Integer
        attribute :has_agriculture, Boolean
        attribute :has_industry,    Boolean
        attribute :has_energy,      Boolean
      end

      validates :area_attribute, presence: true
      validates :value,          presence: true, numericality: true
      validates :base_value,     presence: true, numericality: true

      def factor
        value.to_r / base_value.to_r
      end
    end
  end
end
