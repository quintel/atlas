namespace :debug do
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end

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
    require 'tome'

    Tome.data_dir = args.data_dir

    graph  = Tome::GraphBuilder.build(args.sector.to_sym)
    runner = Tome::Runner.new(Tome::Dataset.find(:nl), graph)
    exception = nil

    puts 'Setting up graph structure... '
    runner.graph

    puts 'Setting up Refinery graph... '

    silence_stream(STDOUT) do
      # Silence warning messages.
      runner.refinery_graph
    end

    print 'Performing Refinery calculations... '

    begin
      runner.calculate
    rescue Refinery::IncalculableGraphError => ex
      print '(incalculable graph) '
      exception = ex
    rescue Refinery::FailedValidationError => ex
      print '(failed validation) '
      exception = ex
    end

    puts

    debugger_dir = Tome.root.join('tmp/debug')
    FileUtils.mkdir_p(debugger_dir)

    puts "Drawing debug info to #{ debugger_dir.to_s }"
    Refinery::VisualDebugger.new(runner.refinery_graph).draw_to(debugger_dir)

    if exception
      puts
      puts exception.message
    end
  end # task :transport
end # namespace :debug
