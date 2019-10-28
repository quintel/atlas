# frozen_string_literal: true

module Atlas
  class Runner
    # Given a dataset, returns a proc which will "zero-out" sub-sectors which
    # are disabled in the dataset. For example, any dataset with a truthy value
    # for "has_metal" will cause all metal nodes and edges to be given zero
    # demand.
    module ZeroDisabledSectors
      # Maps boolean flags on the dataset to node groups which should be
      # disabled if the flag is false.
      FEATURE_MAP = { has_metal: :steel_alu_prod }.freeze

      # Public: Creates a proc which can be used by Refinery to zero-out any
      # disabled subsectors.
      def self.with_dataset(dataset)
        # Create an array of namespaces which have been disabled in the
        # given dataset.
        disabled_groups = FEATURE_MAP.reject do |ds_attribute, _group|
          dataset.send(ds_attribute)
        end.map(&:last)

        lambda do |refinery|
          disabled_nodes =
            refinery.nodes.select do |node|
              (node.get(:model).groups & disabled_groups).any?
            end

          disabled_nodes.each(&method(:zero!))

          refinery
        end
      end

      # Internal: Given a node, zeros out its demand, and sets the associated
      # edges and slots to be zero.
      #
      # Returns nothing.
      def self.zero!(node)
        (node.out_edges.to_a + node.in_edges.to_a).each do |edge|
          edge.set(:child_share, 0)
          edge.set(:parent_share, 0)
          edge.set(:demand, 0)
        end

        (node.slots.out.to_a + node.slots.in.to_a).each do |slot|
          slot.set(:share, 0)
        end

        node.set(:demand, 0)

        # Temporary coupling_carrier slot shares.
        node.set(:cc_in, 0)
        node.set(:cc_out, 0)
      end
    end
  end
end
