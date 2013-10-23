namespace :yaml do
  desc <<-DESC
    Import nodes from the old format to ActiveDocument.

    Reads the legacy export.graph file and the "nl" dataset, and creates
    new-style ActiveDocument files for each node.

    This starts by *deleting* everything in data/nodes on the assumption that
    there are no hand-made changes.
  DESC
  task :nodes, [:from, :to] => [:setup] do |_, args|
    queries # Cache old queries before deleting the nodes.

    include Atlas

    # Wipe out *everything* in the nodes directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    FileUtils.rm_rf(Atlas::Node.directory)

    runner = ImportRun.new('nodes')

    preset_demand_nodes = YAML.load_file(
      Atlas.data_dir.join('import/preset_demand_nodes.yml'))

    nodes_by_sector.each do |sector, nodes|
      nodes.each do |key, data|
        next if IGNORED_NODES.include?(key.to_sym)

        runner.item do
          unless data['slots']
            fail RuntimeError.new("Node #{ key.inspect } has no slots?!")
          end

          klass = node_subclass(key, data)

          # Split the original slots array into two, containing the outgoing
          # and incoming slots respectively. This is done by recognising that
          # outgoing slots begin with the carrier key in (brackets).
          out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }

          data[:groups] = []

          if preset_demand_nodes.include?(key.to_sym)
            data[:groups] << :preset_demand
          end

          # Check out whether there are any groups that this node belongs to.
          node_groups.each do |group_key, values|
            if values.include?(key) || values.include?(key.gsub(/_rdr$/, ''))
              data[:groups] << group_key
            end
          end

          data[:groups] = nil if data[:groups].empty?

          # See whether there are associated costs and integrate them with the
          # attribute list
          data.merge!(node_costs[key]) if node_costs[key]

          # See whether we have something to say about this node's employment
          # properties...
          if node_employment_properties[key]
            data.merge!(node_employment_properties[key])
          end

          # These are calculated by Refinery...
          data.delete(:demand_expected_value)
          data.delete(:preset_demand)

          data[:in_slots]  = in_slots.map  { |s| s.match(/\((.*)\)/)[1] }
          data[:out_slots] = out_slots.map { |s| s.match(/\((.*)\)/)[1] }
          data[:path]      = "#{ sector }/#{ key }"

          data[:queries]   = {}

          data.delete('links')
          data.delete('slots')

          orig_queries = if RDR_KEYS.include?(key.to_sym)
            queries[key.to_s.gsub(/_rdr$/, '').to_sym]
          else
            queries[key.to_sym]
          end

          orig_queries.each do |query_data|
            data[:queries][query_data[:attribute]] = query_data[:query].to_s
          end

          klass.new(data)
        end
      end
    end

    runner.finish

    Rake::Task['yaml:slots'].invoke(args.from, args.to)
    Rake::Task['validate:nodes'].invoke(args.to)
  end # task :nodes
end # namespace :yaml