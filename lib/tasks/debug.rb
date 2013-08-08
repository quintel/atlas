namespace :debug do
  SECTORS = %w(
    agriculture households buildings transport
    industry other energy environment )

  # Given a graph, and a diagram class to use, draws a diagram for each
  # sector.
  def draw_diagrams(graph, diagram_klass, name)
    reporter_name = name.gsub(/\d-/, '').gsub('-', ' ')

    Atlas::Term::Reporter.report("Creating \"#{ reporter_name }\" diagrams",
                                 done: :green) do |reporter|
      SECTORS.each do |sector|
        diagram_klass.new(graph, {
          cluster_by: ->(node) {
            node.get(:model).ns
          },
          filter_by:  ->(edge) {
            edge.from.get(:model).ns == sector ||
            edge.to.get(:model).ns == sector
          }
        }).draw_to("tmp/debug/#{ sector }.#{ name }.png")

        reporter.inc(:done)
      end
    end
  end

  desc 'Check if the queries can all be run'
  task check: :environment do
    include Atlas

    graph     = GraphBuilder.build
    runner    = Runner.new(Atlas::Dataset.find(:nl), graph)

    runner.refinery_graph

    puts "All OK!"
  end

  desc 'Output before and after diagrams of all the subgraphs.'
  task graph: :environment do
    include Atlas

    # Set up debug details.

    debug_dir = Atlas.root.join('tmp/debug')
    FileUtils.mkdir_p(debug_dir)
    debug_dir.children.each { |child| child.delete }

    # Off we go...

    graph     = GraphBuilder.build
    runner    = Runner.new(Atlas::Dataset.find(:nl), graph)
    reporter  = Atlas::Term::Reporter.new('Performing calculations', done: :green)

    exception = nil
    summary   = nil

    draw_diagrams(runner.refinery_graph,
                  Refinery::Diagram::InitialValues, '0-initial-values')

    # A custom calculator catalyst which will show in real-time how many
    # elements in the graph have been calculated.
    calculator = Refinery::Catalyst::Calculators.new do |*|
      reporter.inc(:done)
    end

    begin
      reporter.report { |*| runner.calculate(calculator) }
      draw_diagrams(runner.refinery_graph, Refinery::Diagram, '1-finished')
    rescue Refinery::IncalculableGraphError => ex
      puts '  * Incalculable graph'
      exception = ex

      # Summarise the remaining nodes and edges.
      incalculables = ex.message.lines[2..-1].group_by do |message|
        message.match(/:([^_:]+)[a-z0-9_]+>/)[1]
      end

      by_sector = incalculables.map do |sector, lines|
        nodes = lines.select { |l| l.match(/NodeDemand/) }.length
        edges = lines.select { |l| l.match(/EdgeDemand/) }.length

        "#{ (sector + ':').ljust(13) } #{ nodes } nodes and #{ edges } edges"
      end

      summary = <<-EOF.gsub(/^\s+/, '')
        Remaining incalculables: (#{ ex.message.lines.length - 2 })
        ------------------------
        #{ by_sector.join("\n") }
      EOF

      draw_diagrams(runner.refinery_graph,
                    Refinery::Diagram::Incalculable, '1-finished-incalculable')

      draw_diagrams(runner.refinery_graph,
                    Refinery::Diagram::Calculable, '1-finished-calculable')
    rescue Refinery::FailedValidationError => ex
      print '  * Failed validation'
      exception = ex

      draw_diagrams(runner.refinery_graph, Refinery::Diagram, '1-finished')
    end

    puts "Writing static data to #{ Atlas.root.join('tmp/static.yml') }"
    Atlas::Exporter.new(runner.refinery_graph).export_to(Atlas.root.join('tmp/static.yml'))

    if exception
      puts
      puts exception.message
    end

    if summary
      puts
      puts summary
    end
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

    reporter = Atlas::Term::Reporter.new(
      'Performing Refinery calculations', done: :green)

    catalyst =
      Refinery::Catalyst::VisualCalculator.new(debugger_dir) do |calculator|
        reporter.inc(:done)
      end

    Refinery::Diagram::InitialValues.new(runner.refinery_graph).draw_to('tmp/debug/00000.png')

    begin
      reporter.report { |*| runner.calculate }
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

    Refinery::Diagram::Calculable.new(runner.refinery_graph).draw_to('tmp/debug/99999-calculable.png')
    Refinery::Diagram::Incalculable.new(runner.refinery_graph).draw_to('tmp/debug/99999-incalculable.png')

    puts "Writing static data to #{ Atlas.root.join('tmp/static.yml') }"
    Atlas::Exporter.new(runner.refinery_graph).export_to(Atlas.root.join('tmp/static.yml'))

    if exception
      puts
      puts exception.message
    end
  end # task :transport
end # namespace :debug
