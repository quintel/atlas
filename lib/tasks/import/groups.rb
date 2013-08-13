namespace :import do
  desc <<-DESC
    Import groups to ActiveDocument.

    Reads the legacy groups.yml files and registers the groups on the
    respective nodes.
  DESC
  task :groups, [:from, :to] => [:setup] do |_, args|

    include Atlas

    runner = ImportRun.new('groups')

    node_groups.each do |group, nodes|
      nodes.each do |key, data|
        runner.item do
          # Split the original slots array into two, containing the outgoing
          # and incoming slots respectively. This is done by recognising that
          # outgoing slots begin with the carrier key in (brackets).
          out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }

          data[:in_slots]  = in_slots.map  { |s| s.match(/\((.*)\)/)[1] }
          data[:out_slots] = out_slots.map { |s| s.match(/\((.*)\)/)[1] }
          data[:path]      = "#{ sector }/#{ key }"

          data[:queries]   = {}

          data.delete('links')
          data.delete('slots')

          queries[key.to_sym].each do |query_data|
            data[:queries][query_data[:attribute]] = query_data[:query].to_s
          end

          klass.new(data)
        end
      end
    end

    runner.finish

    Rake::Task['import:slots'].invoke(args.from, args.to)
    Rake::Task['validate:nodes'].invoke(args.to)
  end # task :nodes
end # namespace :import
