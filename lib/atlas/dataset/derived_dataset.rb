module Atlas
  class Dataset::DerivedDataset < Dataset
    GRAPH_FILENAME = 'graph.yml'.freeze

    attribute :base_dataset, String
    attribute :scaling,      Preset::Scaling
    attribute :init,         Hash[Symbol => Float]

    validates :scaling, presence: true
    validates :base_dataset, presence: true

    validate :base_dataset_exists
    validate :scaling_valid
    validate :init_keys_exist
    validate :init_values_present
    validate :share_groups_exist, if: -> { ! errors.messages[:init] }
    validate :share_groups_sum,   if: -> { ! errors.messages[:init] }

    def graph
      @graph ||= GraphDeserializer.build(YAML.load_file(graph_path))
    end

    def graph_path
      File.join(directory, key.to_s, GRAPH_FILENAME)
    end

    private

    def base_dataset_exists
      unless Dataset::FullDataset.exists?(base_dataset)
        errors.add(:base_dataset, 'does not exist')
      end
    end

    def scaling_valid
      if scaling
        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end
    end

    def init_keys_exist
      init.each_pair do |key, value|
        unless InitializerInput.exists?(key)
          errors.add(:init, "initializer input '#{ key }' does not exist")
        end
      end
    end

    def init_values_present
      init.each_pair do |key, value|
        unless value.present?
          errors.add(:init, "value for initializer input '#{ key }' can't be blank")
        end
      end
    end

    def share_groups
      init.each_with_object({}) do |(key, value), result|
        input = InitializerInput.find(key)

        result[input.share_group] ||= {}
        result[input.share_group][input] = value
      end
    end

    def share_groups_exist
      share_groups.each_pair do |share_group, inputs|
        missing = InitializerInput.by_share_group[share_group] - inputs.keys

        if missing.any?
          errors.add(:init, "share group '#{ share_group }' is missing the "\
                     "following share(s): #{ missing.map(&:key).join(', ') }")
        end
      end
    end

    def share_groups_sum
      share_groups.each do |share_group, inputs|
        unless inputs.values.sum == 100.0
          errors.add(:init, "share group '#{ share_group }' doesn't add up to 100%")
        end
      end
    end
  end # Dataset::DerivedDataset
end # Atlas
