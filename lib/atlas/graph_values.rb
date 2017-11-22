module Atlas
  class GraphValues
    include ActiveModel::Validations

    GRAPH_VALUES_FILENAME = 'graph_values.yml'.freeze
    VALID_GRAPH_METHODS   = %w(
      preset_demand
      max_demand
      demand
      share
      conversion
      reserved_fraction
      number_of_units
    ).freeze

    attr_accessor :values

    validate :validate_presence_of_init_values
    validate :validate_presence_of_init_keys

    validates_with Atlas::ActiveDocument::WhitelistingInitializerMethods,
      attribute: :values

    validates_with Atlas::ActiveDocument::ShareGroupTotalValidator,
      attribute: :values

    validates_with Atlas::ActiveDocument::ShareGroupInclusionValidator,
      attribute: :values

    def initialize(derived_dataset)
      @derived_dataset = derived_dataset
    end

    def values
      @values ||= YAML.load_file(graph_values_path)
    end

    def set(element, attribute, value)
      previous = values
      previous[element.key] ||= {}
      previous[element.key][attribute] = value

      save(previous.to_yaml)
    end

    alias_method :to_h, :values

    def save(yaml = "--- {}")
      File.write(graph_values_path, yaml)
    end

    private

    def validate_presence_of_init_keys
      values.each_pair do |_, values|
        next if values.blank?

        values.each_pair do |method, _|
          unless VALID_GRAPH_METHODS.include?(method)
            errors.add(:values, "'#{ method }' does not exist as a graph method")
          end
        end
      end
    end

    def validate_presence_of_init_values
      values.each_pair do |key, value|
        unless value.present?
          errors.add(:values, "value for node/edge/slot '#{ key }' can't be blank")
        end
      end
    end


    def graph_values_path
      @derived_dataset.dataset_dir.
        join(GRAPH_VALUES_FILENAME)
    end
  end
end
