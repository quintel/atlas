namespace :import do
  desc <<-DESC
    Import edges from the old format to ActiveDocument.

    This starts by *deleting* everything in data/edges on the assumption that
    there are no hand-made changes.
  DESC
  task :edges, [:from, :to] => [:setup] do |_, args|
    queries # Cache old queries before deleting the edges.

    include Atlas

    # Wipe out *everything* in the edges directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    FileUtils.rm_rf(Edge.directory)

    link_re = /
      (?<consumer>[\w_]+)-       # Child node key
      \([^)]+\)\s                # Carrier key (ignored)
      (?<reversed><)?            # Arrow indicating a reversed link?
      --\s(?<type>\w)\s-->?\s    # Link type and arrow
      \((?<carrier>[^)]+)\)-     # Carrier key
      (?<supplier>[\w_]+)        # Parent node key
    /xi

    runner = ImportRun.new('edges')

    nodes_by_sector.each do |sector, nodes|
      sector_dir = Edge.directory.join(sector)
      edges      = nodes.map { |key, node| node['links'] }.flatten.compact

      edges.each do |link|
        runner.item do
          data = link_re.match(link)

          type = case data[:type]
            when 's' then :share
            when 'f' then :flexible
            when 'c' then :constant
            when 'd' then :dependent
            when 'i' then :inverse_flexible
          end

          # We currently have to construct the full path manually since Edge
          # does not (yet) account for the sector.
          key   = Edge.key(data[:consumer], data[:supplier], data[:carrier])
          path  = sector_dir.join(key.to_s)

          props = { path: path, type: type, queries: {},
                    reversed: ! data[:reversed].nil? }

          queries[key].each do |query_data|
            props[:queries][query_data[:attribute]] = query_data[:query].to_s
          end

          Edge.new(props)
        end
      end
    end # nodes_by_sector.each

    runner.finish

    Rake::Task['validate:edges'].invoke(args.to)
  end # task :edges
end # namespace :import
