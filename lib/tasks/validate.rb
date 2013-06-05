namespace :validate do
  # Given an ActiveDocument class, runs the validations on all of the
  # documents and reports the success or failure thereof.
  class ValidationRunner
    def initialize(*classes)
      @classes = classes
    end

    # Public: Loads each document and runs its validations.
    #
    # Returns nothing.
    def run
      failures = []

      @classes.each do |klass|
        each_document(klass) do |document|
          if document.valid?
            print Term::ANSIColor.green { '.' }
          else
            print Term::ANSIColor.red { 'F' }
            failures.push(document)
          end

          yield document if block_given?
        end
      end

      print_failures(failures)
      failures.any? ? puts : puts("\n\n")
    end

    #######
    private
    #######

    # Internal: A nice human-readable version of the +@klass+ name.
    #
    # Returns a string.
    def class_name(klass)
      klass.name.gsub(/^Tome::/, '')
    end

    # Internal: Returns the path of a document, relative to the Tome data
    # directory.
    #
    # Returns a Pathname
    def rel_path(document)
      document.path.relative_path_from(Tome.data_dir)
    end

    # Internal: Load each document one-at-a-time and validate, rather than
    # waiting a few seconds for all the documents to load first.
    #
    # Yields each document.
    #
    # Returns nothing.
    def each_document(klass)
      klass.manager.keys.each { |key| yield klass.find(key) }
    end

    # Internal: Outputs information about each failure.
    #
    # failures - An array of documents whose validations failed.
    #
    # Returns nothing.
    def print_failures(failures)
      if failures.any?
        puts "\n\n"
        puts "Failures: (#{ failures.length })\n"
      end

      failures.each_with_index do |document, index|
        puts
        print "  #{ index + 1 }) #{ class_name(document.class) }: "
        puts "#{ document.key }"
        puts Term::ANSIColor.cyan { "    ./#{ rel_path(document) }" }
        puts

        errors = document.errors.map do |attr, error|
          # Add white space to all lines.
          "- #{ attr } #{ error }".gsub(/^/, '    ')
        end

        puts Term::ANSIColor.red { errors.join("\n") }
      end
    end
  end # ValidationRunner

  # --------------------------------------------------------------------------

  task :setup, [:dir] do |_, args|
    require 'term/ansicolor'
    Tome.data_dir = args.dir || '../etsource/data'
  end

  task(carriers: :setup) { ValidationRunner.new(Tome::Carrier).run }
  task(datasets: :setup) { ValidationRunner.new(Tome::Dataset).run }
  task(edges: :setup)    { ValidationRunner.new(Tome::Edge).run }
  task(gqueries: :setup) { ValidationRunner.new(Tome::Gquery).run }
  task(inputs: :setup)   { ValidationRunner.new(Tome::Input).run }
  task(nodes: :setup)    { ValidationRunner.new(Tome::Node).run }
  task(presets: :setup)  { ValidationRunner.new(Tome::Preset).run }
  task(slots: :setup)    { ValidationRunner.new(Tome::Slot).run }

  task all: :setup do
    ValidationRunner.new(
      Tome::Carrier, Tome::Dataset, Tome::Edge,   Tome::Gquery,
      Tome::Input,   Tome::Node,    Tome::Preset, Tome::Slot
    ).run
  end
end # :validate

desc 'Runs the validations on all of the documents'
task :validate, [:dir] => ['validate:all'] 
