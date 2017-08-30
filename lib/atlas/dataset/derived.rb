module Atlas
  class Dataset::Derived < Dataset
    GRAPH_FILENAME             = 'graph.yml'.freeze
    INITIALIZER_INPUT_FILENAME = 'initializer_inputs.yml'.freeze
    VALID_INITIALIZER_INPUTS   = %w(demand_setter share_setter unit_setter).freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :geo_id,       String

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling
    validate :validate_presence_of_init_keys, if: -> { persisted? }
    validate :validate_presence_of_init_values, if: -> { persisted? }
    validate :validate_whitelisting_of_init, if: -> { persisted? }
    validate :validate_presence_of_graph_file

    validates_with SerializedGraphValidator

    validates_with ShareGroupTotalValidator,
      attribute: :initializer_inputs, if: -> { persisted? }

    validates_with ShareGroupInclusionValidator,
      attribute: :initializer_inputs, if: -> { persisted? }

    def self.find_by_geo_id(geo_id)
      all.detect do |item|
        item.geo_id == geo_id
      end
    end

    def to_hash(*)
      super.merge(initializer_inputs: initializer_inputs)
    end

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      dataset_dir.join(GRAPH_FILENAME)
    end

    def initializer_inputs
      @initializer_inputs ||= YAML.load_file(initializer_input_path)
    end

    def initializer_input_path
      dataset_dir.join(INITIALIZER_INPUT_FILENAME)
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
      initializer_inputs.each_key do |key|
        unless VALID_INITIALIZER_INPUTS.include?(key)
          errors.add(:initializer_inputs, "'#{ key }' does not exist as an initializer input")
        end
      end
    end

    def validate_presence_of_init_values
      initializer_inputs.each_pair do |key, value|
        unless value.present?
          errors.add(:initializer_inputs, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end

    def validate_whitelisting_of_init
      return if (errors.messages[:initializer_inputs] || []).any?

      initializer_inputs.each_pair do |key, elements|
        elements.each_key do |graph_key|
          graph_type, graph_element = if graph_key =~ /-/
                                        [:edge, Edge.find(graph_key)]
                                      else
                                        [:node, Node.find(graph_key)]
                                      end

          unless graph_element.initializer_inputs.include?(key)
            errors.add(:initializer_inputs, "#{ graph_type } '#{ graph_key }' is not allowed to be edited by '#{ key }'")
          end
        end
      end
    end

    def validate_presence_of_graph_file
      if persisted? && !graph_path.file?
        errors.add(:graph, "graph.yml file is missing")
      end
    end
  end # Dataset::Derived
end # Atlas
