module Atlas
  # Wraps around the Runner to provide feedback to the CLI on the progress
  # of the calculation process. Optionally outputs before and after diagrams
  # of each sector.
  class DebugRunner
    MESSAGES = [
      'Reticulating splines',
      'Prefixing words with "ET"',
      "Solving the worlds' problems",
      'No errors yet',
      'Something, something, graph',
      'Searching for lost house keys',
      'Creating the universe'
    ]

    SECTORS = %w(
      agriculture households buildings transport
      industry other bunkers energy environment
    ).map(&:upcase)

    # Public: Creates a new DebugRunner.
    #
    # dataset   - The Atlas::Dataset whose demands and shares are to be
    #             calculated.
    # directory - The path to a directory in which to store debug output and
    #             diagrams. nil will disable diagram output.
    #
    # Retuns a DebugRunner.
    def initialize(dataset, directory = nil, diagrams = SECTORS)
      require 'ruby-progressbar'

      @dataset   = dataset
      @runner    = nil
      @error     = nil

      @diagrams  = diagrams

      if directory
        @directory = Pathname.new(directory).join(
          "debug-#{ Time.now.strftime('%s') }")
      end

      if @directory.nil? && @diagrams.any?
        raise 'Directory argument is mandatory when creating diagrams'
      end
    end

    # Public: The progress bar used to inform the user of the progress of the
    # calculation.
    #
    # Returns a ProgressBar.
    def bar
      @bar ||= ProgressBar.create(
        total: nil, format: '%t: |%B| %p%%, %a',
        unknown_progress_animation_steps: ['   =', '=   ', ' =  ', '  = ']
      )
    end

    # Public: Runs the debug runner.
    #
    # Returns the calculated graph.
    def run!
      puts "Debug output will be saved to #{ @directory }"

      graph_setup!
      calculate!
      post_calculation!

      bar.title = 'Finished'
      bar.total = bar.progress

      @runner.refinery_graph
    rescue Refinery::RefineryError => ex
      @error = ex

      post_calculation!

      bar.title = 'INSUFFICIENT DATA FOR A MEANINGFUL ANSWER'
      bar.total = bar.progress

      puts ; puts @error

      @runner.refinery_graph
    end

    private

    # Internal: Creates the thread which loads the graph structure, and runs
    # the queries.
    def graph_setup!
      with_animated_bar do
        bar.title = 'Building structure'

        bar.title = MESSAGES.sample
        @runner = Runner.new(@dataset)
        @runner.refinery_graph

        draw_diagrams(Refinery::Diagram::InitialValues, 'initial')
      end
    end

    # Internal: Runs the Refinery calculations, informing the user as progress
    # is made.
    def calculate!
      bar.title = 'Calculating'

      # Determine how many nodes and edges have to be calculated, so that we
      # can update the bar...
      bar.total = bar.progress + @runner.refinery_graph.nodes.sum do |node|
        (node.demand ? 0 : 1) + node.out_edges.reject(&:demand).to_a.length
      end + 1

      calculator = Refinery::Catalyst::Calculators.new { |*| bar.increment }

      @runner.calculate(calculator)
    end

    # Internal: Creates a thread which deals with post-calculation tasks, such
    # as showing the finished diagrams.
    def post_calculation!
      with_animated_bar do
        bar.title = 'Writing trace info'

        FileUtils.mkdir_p(@directory)

        File.write(
          @directory.join('_trace.txt'),
          Refinery::GraphDebugger.new(@runner.refinery_graph)
        )

        if @error
          draw_diagrams(Refinery::Diagram::Calculable,   'calculable')
          draw_diagrams(Refinery::Diagram::Incalculable, 'incalculable')
        else
          draw_diagrams(Refinery::Diagram::Base, 'finished')
        end
      end
    end

    # Internal: Runs a block in a thread, while showing an animated progress
    # bar to the user.
    def with_animated_bar(&block)
      main = Thread.new do
        begin
          block.call
        ensure
          @animation.terminate if @animation && @animation.alive?
        end
      end

      [main, bar_animation_thread].each(&:join)
    end

    # Internal: Creates a thread which increments the progress bar once every
    # 100ms. This is used to animate the bar when we don't know how long a
    # task will take to complete.
    def bar_animation_thread
      @animation = Thread.new do
        bar.total = nil

        while true do
          bar.increment
          sleep(0.1)
        end
      end
    end

    # Internal: Draws each of the diagrams requested by the user.
    def draw_diagrams(klass, name)
      title = "Creating #{ name } diagrams (%d of #{ @diagrams.length })"

      @diagrams.each.with_index do |filter, index|
        bar.title = sprintf(title, index + 1)
        draw_diagram(klass, filter, name)
      end
    end

    # Internal: Draws an individual diagram requested by the users.
    def draw_diagram(klass, filter, name)
      filters = filter.split('+').map do |str|
        if str.match(/^[A-Z]+$/)
          # Namespace (sector) filter.
          namespace = str.downcase
          ->(node) { node.get(:model).ns?(namespace) }
        else
          # Node key filter.
          key = str.to_sym
          ->(node) { node.key == key }
        end
      end

      FileUtils.mkdir_p(@directory)

      klass.new(@runner.refinery_graph, {
        format_demand: ->(value) {
          value / 1000
        },
        cluster_by: ->(node) {
          node.get(:model).ns
        },
        filter_by: ->(edge) {
          filters.any? { |filter| filter.call(edge.from) } ||
          filters.any? { |filter| filter.call(edge.to) }
        }
      }).draw_to(@directory.join("#{ filter.downcase[0..50] }.#{ name }.png"))
    end

  end
end
