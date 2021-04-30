# frozen_string_literal: true

module Atlas
  class Dataset
    # Represents a dataset which is based and scaled on a full-size, "normal" dataset.
    class Derived < Dataset
      attribute :init,         Hash[Symbol => Float]
      attribute :base_dataset, String
      attribute :scaling,      Preset::Scaling
      attribute :geo_id,       String
      attribute :uses_deprecated_initializer_inputs, Boolean, default: false

      # Delegate some methods which might be called in `Runner` to the parent dataset.
      delegate :energy_balance, to: :parent
      delegate :fce, to: :parent

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
        all.detect { |item| item.geo_id == geo_id }
      end

      def initialize(*args)
        super

        # A map of load profile keys to booleans. A truthy value means the derived dataset has a
        # custom curve matching the key, false that the parent curve should be used.
        @load_profile_map = {}
      end

      def graph_values
        @graph_values ||= GraphValues.new(self)
      end

      def parent
        Dataset::Full.find(base_dataset)
      end

      private

      # Internal: Paths used to look for CSV and other dataset-related files.
      def resolve_paths
        [dataset_dir, parent.dataset_dir]
      end

      def validate_presence_of_base_dataset
        return if Dataset::Full.exists?(base_dataset)

        errors.add(:base_dataset, 'does not exist')
      end

      def validate_scaling
        return unless scaling

        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end

      def validate_presence_of_init_keys
        init.each_key do |key|
          unless InitializerInput.exists?(key)
            errors.add(:init, "'#{key}' does not exist as an initializer input")
          end
        end
      end

      def validate_presence_of_init_values
        init.each_pair do |key, value|
          unless value.present?
            errors.add(:init, "value for initializer input '#{key}' can't be blank")
          end
        end
      end

      def validate_graph_values
        return if graph_values.valid?

        graph_values.errors.each do |_, message|
          errors.add(:graph_values, message)
        end
      end
    end
  end
end
