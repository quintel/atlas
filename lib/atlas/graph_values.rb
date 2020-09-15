module Atlas
  class GraphValues
    include ActiveModel::Validations

    GRAPH_VALUES_FILENAME = 'graph_values.yml'.freeze
    VALID_GRAPH_METHODS   = %w(
      demand
      max_demand
      share
      child_share
      parent_share
      number_of_units
      input
      output
      full_load_hours
    ).freeze

    attr_accessor :values

    validate :validate_presence_of_init_values
    validate :validate_presence_of_init_keys

    validates_with Atlas::ActiveDocument::WhitelistingInitializerMethods,
      attribute: :values

    # validates_with Atlas::ActiveDocument::ShareGroupTotalValidator,
    #   attribute: :values, share_attribute: :parent_share, sum: 1.0

    # validates_with Atlas::ActiveDocument::ShareGroupTotalValidator,
    #   attribute: :values, share_attribute: :child_share, sum: 1.0

    # validates_with Atlas::ActiveDocument::ShareGroupInclusionValidator,
    #   attribute: :values, share_attribute: :parent_share

    # validates_with Atlas::ActiveDocument::ShareGroupInclusionValidator,
    #   attribute: :values, share_attribute: :child_share

    def initialize(derived_dataset)
      @derived_dataset = derived_dataset
    end

    def values
      @values ||= YAML.load_file(graph_values_path)
    end

    def for(element, attribute = nil)
      attributes = values[element.key.to_s]

      if attribute
        attributes.fetch(attribute.to_s)
      else
        attributes
      end
    end

    def set(element_key, attribute, value)
      values[element_key.to_s] ||= {}
      values[element_key.to_s].deep_merge!(Hash[attribute.to_s, value])
    end

    alias_method :to_h, :values

    def create!
      remove_instance_variable(:@values) if @values
      save("--- {}")
    end

    def save(yaml = values.to_yaml)
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
