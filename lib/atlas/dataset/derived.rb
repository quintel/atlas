# frozen_string_literal: true

module Atlas
  class Dataset
    # Represents a dataset which is based and scaled on a full-size, "normal" dataset.
    class Derived < Dataset
      attribute :init,         Hash[Symbol => Float]
      attribute :base_dataset, String
      attribute :scaling,      Dataset::Scaling
      attribute :geo_id,       String

      # Delegate some methods which might be called in `Runner` to the parent dataset.
      delegate :energy_balance, to: :parent

      validates :scaling, presence: true

      validate :validate_presence_of_base_dataset
      validate :validate_scaling

      validate :validate_graph_values,
        if: -> { persisted?}

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
        Dataset.find(base_dataset)
      end

      private

      def validate_presence_of_base_dataset
        unless Dataset.exists?(base_dataset)
          errors.add(:base_dataset, 'does not exist')
          return
        end

        unless has_full_parent?
          errors.add(:base_dataset, 'has no Full parent')
        end
      end

      def validate_scaling
        return unless scaling

        scaling.valid?
        scaling.errors.full_messages.each do |message|
          errors.add(:scaling, message)
        end
      end

      def validate_graph_values
        return if graph_values.valid?

        graph_values.errors.each do |_, message|
          errors.add(:graph_values, message)
        end
      end

      def has_full_parent?
        return false unless Dataset.exists?(base_dataset)
        Dataset::Full.exists?(base_dataset) || parent&.has_full_parent?
      end

      def resolve_paths
        ([dataset_dir] + Array(parent&.resolve_paths)).uniq
      end
    end
  end
end
