namespace :debug do
  SECTORS = %w(
    agriculture households buildings transport
    industry other energy environment )

  # Given a graph, and a diagram class to use, draws a diagram for each
  # sector.
  def draw_diagrams(graph, diagram_klass, name)
    return if ENV['FAST']

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
      draw_diagrams(runner.refinery_graph, Refinery::Diagram::Base, '1-finished')
    rescue Refinery::IncalculableGraphError => ex
      puts '  * Incalculable graph'
      exception = ex

      # Summarise the remaining nodes and edges.
      incalculables = ex.message.lines.to_a[2..-1].group_by do |message|
        message.match(/:([^_:]+)[a-z0-9_]+>/)[1]
      end

      by_sector = incalculables.map do |sector, lines|
        nodes = lines.select { |l| l.match(/NodeDemand/) }.to_a.length
        edges = lines.select { |l| l.match(/EdgeDemand/) }.to_a.length

        "#{ (sector + ':').ljust(13) } #{ nodes } nodes and #{ edges } edges"
      end

      summary = <<-EOF.gsub(/^\s+/, '')
        Remaining incalculables: (#{ ex.message.lines.to_a.length - 2 })
        ------------------------
        #{ by_sector.join("\n") }
      EOF

      puts
      puts summary
      puts

      draw_diagrams(runner.refinery_graph,
                    Refinery::Diagram::Incalculable, '1-finished-incalculable')

      draw_diagrams(runner.refinery_graph,
                    Refinery::Diagram::Calculable, '1-finished-calculable')
    rescue Refinery::FailedValidationError => ex
      puts '  * Failed validation'
      exception = ex

      draw_diagrams(runner.refinery_graph, Refinery::Diagram::Base, '1-finished')
    end

    puts "Writing static data to #{ Atlas.root.join('tmp/static.yml') }"
    Atlas::Exporter.new(runner.refinery_graph).export_to(Atlas.root.join('tmp/static.yml'))

    File.write(
      debug_dir.join('_trace.txt'),
      Refinery::GraphDebugger.new(runner.refinery_graph))

    if exception
      puts
      puts exception.message
    end

    if summary
      puts
      puts summary
    end
  end # task :graph
end # namespace :debug
