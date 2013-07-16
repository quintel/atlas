namespace :debug do
  desc 'Output before and after diagrams of the transport subgraph.'
  task :subgraph, [:data_dir, :sector] do |_, args|
    if args.data_dir.nil?
      raise "You need to supply the path to ETSource data; "\
            "e.g. rake debug:subgraph[../etsource/data,transport]"
    end

    if args.sector.nil?
      raise "You need to supply a sector name; "\
            "e.g. rake debug:subgraph[../etsource/data,transport]"
    end

    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))
    require 'atlas'

    Atlas.data_dir = args.data_dir

    debugger_dir = Atlas.root.join('tmp/debug')
    FileUtils.mkdir_p(debugger_dir)
    debugger_dir.children.each { |child| child.delete }

    graph  = Atlas::GraphBuilder.build(args.sector.to_sym)
    runner = Atlas::Runner.new(Atlas::Dataset.find(:nl), graph)

    exception = nil

    puts 'Setting up graph structure... '
    runner.graph

    puts 'Setting up Refinery graph... '
    runner.refinery_graph

    print 'Performing Refinery calculations... '

    begin
      runner.calculate(Refinery::Catalyst::VisualCalculator.new(debugger_dir))
    rescue Refinery::IncalculableGraphError => ex
      print '(incalculable graph) '
      exception = ex
    rescue Refinery::FailedValidationError => ex
      print '(failed validation) '
      exception = ex
    end

    puts

    text_debugger = Refinery::GraphDebugger.new(runner.refinery_graph)
    File.write(debugger_dir.join('_debug.txt'), text_debugger.to_s)

    puts "Writing static data to #{ Atlas.root.join('tmp/static.yml') }"
    Atlas::Exporter.new(runner.refinery_graph).export_to(Atlas.root.join('tmp/static.yml'))

    if exception
      puts
      puts exception.message
    end
  end # task :transport
end # namespace :debug
