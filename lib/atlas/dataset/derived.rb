module Atlas
  class Dataset::Derived < Dataset
    attribute :init,         Hash[Symbol => Float]
    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :geo_id,       String
    attribute :uses_deprecated_initializer_inputs, Boolean, default: false

    # Delegate any method which might be called in `Runner` to the parent dataset.
    delegate :central_producers, to: :parent
    delegate :demands, to: :parent
    delegate :efficiencies, to: :parent
    delegate :energy_balance, to: :parent
    delegate :fce, to: :parent
    delegate :insulation_costs, to: :parent
    delegate :parent_values, to: :parent
    delegate :primary_production, to: :parent
    delegate :shares, to: :parent

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling

    validate :validate_presence_of_init_keys,
      if: -> { uses_deprecated_initializer_inputs }

    validate :validate_presence_of_init_values,
      if: -> { uses_deprecated_initializer_inputs }

    validate :validate_graph_values,
      if: -> { persisted? && !uses_deprecated_initializer_inputs }

    def self.find_by_geo_id(geo_id)
      all.detect do |item|
        item.geo_id == geo_id
      end
    end

    def graph_values
      @graph_values ||= GraphValues.new(self)
    end

    def parent
      Dataset::Full.find(base_dataset)
    end

    private

    def validate_presence_of_base_dataset
      unless Dataset::Full.exists?(base_dataset)
        errors.add(:base_dataset, 'does not exist')
      end
    end

    def validate_scaling
      if scaling
        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end
    end

    def validate_presence_of_init_keys
      init.each_key do |key|
        unless InitializerInput.exists?(key)
          errors.add(:init, "'#{ key }' does not exist as an initializer input")
        end
      end
    end

    def validate_presence_of_init_values
      init.each_pair do |key, value|
        unless value.present?
          errors.add(:init, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end

    def validate_graph_values
      unless graph_values.valid?
        graph_values.errors.each do |_, message|
          errors.add(:graph_values, message)
        end
      end
    end
  end
end
