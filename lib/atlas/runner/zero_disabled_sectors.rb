module Atlas
  class Runner
    # Given a dataset, returns a proc which will "zero-out" sub-sectors which
    # are disabled in the dataset. For example, any dataset with a truthy value
    # for "has_metal" will cause all metal nodes and edges to be given zero
    # demand.
    module ZeroDisabledSectors
      # Maps boolean flags on the dataset to node namespaces which should be
      # disabled if the flag is false.
      FEATURE_MAP = { has_metal: 'industry.metal' }

      # Public: Creates a proc which can be used by Refinery to zero-out any
      # disabled subsectors.
      def self.with_dataset(dataset)
        # Create an array of namespaces which have been disabled in the
        # given dataset.
        disabled_ns = FEATURE_MAP.reject do |ds_attribute, namespace|
          dataset.send(ds_attribute)
        end.map(&:last)

        lambda do |refinery|
          refinery.nodes.each do |node|
            if disabled_ns.any? { |namespace| node.get(:model).ns?(namespace) }
              node.set(:demand, 0)
            end
          end

          refinery
        end
      end
    end # ZeroDisabledSectors
  end # Runner
end # Atlas
