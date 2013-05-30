namespace :import do
  desc <<-DESC
    Import nodes from the old format to ActiveDocument.

    Reads the legacy export.graph file and the "nl" dataset, and creates
    new-style ActiveDocument files for each node.

    This starts by *deleting* everything in data/nodes on the assumption that
    there are no hand-made changes.
  DESC
  task :nodes, [:to, :from] => [:setup] do |_, args|
    include Tome

    # Wipe out *everything* in the nodes directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    FileUtils.rm_rf(Tome::Node.directory)

    runner = ImportRun.new('nodes')

    nodes_by_sector.each do |sector, nodes|
      nodes.each do |key, data|
        runner.item do
          unless data['slots']
            raise RuntimeError.new("Node #{ key.inspect } has no slots?!")
          end

          klass = node_subclass(key, data)

          # Split the original slots array into two, containing the outgoing
          # and incoming slots respectively. This is done by recognising that
          # outgoing slots begin with the carrier key in (brackets).
          out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }

          data[:in_slots]  = in_slots.map  { |s| s.match(/\((.*)\)/)[1] }
          data[:out_slots] = out_slots.map { |s| s.match(/\((.*)\)/)[1] }

          data.delete('links')
          data.delete('slots')

          data[:query] = queries[key.to_sym] if queries.key?(key.to_sym)
          data[:path]  = "#{ sector }/#{ key }"

          klass.new(data)
        end
      end
    end

    runner.finish
  end # task :nodes
end # namespace :import
