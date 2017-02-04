module Atlas
  class Runner
    # Given a dataset, returns a proc which will "zero-out" sub-sectors which
    # are disabled in the dataset. For example, any dataset with a truthy value
    # for "has_metal" will cause all metal nodes and edges to be given zero
    # demand.
    module ZeroDisabledSectors
      # Maps boolean flags on the dataset to node groups which should be
      # disabled if the flag is false.
      FEATURE_GROUPS = { has_metal: :metal_industry }
      FEATURE_SECTORS = { has_industry:    :industry,
                          has_agriculture: :agriculture }


      # Public: Creates a proc which can be used by Refinery to zero-out any
      # disabled subsectors.
      def self.with_dataset(dataset)
        # Create an array of namespaces which have been disabled in the
        # given dataset.
        disabled_groups = FEATURE_GROUPS.reject do |ds_attribute, _|
          dataset.send(ds_attribute)
        end.map(&:last)

        disabled_sectors = FEATURE_SECTORS.reject do |ds_attribute, _|
          dataset.send(ds_attribute)
        end.map(&:last).map(&:to_s)

        lambda do |refinery|
          disabled_nodes = refinery.nodes.select do |node|
            disabled_sectors.include?(node.get(:model).sector.to_s) ||
              (node.get(:model).groups & disabled_groups).any?
          end

          # @@@ debug
          p "ZeroDisabledSectors", dataset.key, disabled_groups, disabled_sectors
          puts disabled_nodes.map(&:key)

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
      end
    end # ZeroDisabledSectors
  end # Runner

end # Atlas
