module Atlas
  class Dataset::Derived < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :init,         Hash[Symbol => Float]
    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :geo_id,       String
    attribute :uses_deprecated_initializer_inputs, Boolean, default: false

    validates :scaling, presence: true

    validate :validate_presence_of_base_dataset
    validate :validate_scaling
    validate :validate_presence_of_graph_file

    validate :validate_graph_values, if: -> { persisted? }

    validates_with SerializedGraphValidator

    def self.find_by_geo_id(geo_id)
      all.detect do |item|
        item.geo_id == geo_id
      end
    end

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      dataset_dir.join(GRAPH_FILENAME)
    end

    def graph_values
      @graph_values ||= GraphValues.new(self)
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

    def validate_graph_values
      return if uses_deprecated_initializer_inputs

      unless graph_values.valid?
        graph_values.errors.each do |_, message|
          errors.add(:graph_values, message)
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
