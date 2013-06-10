# Contains tasks used to convert the old-style ETSource files into the new
# shiny ActiveDocuments. In order to complete the import, the tasks need to
# know the path to the root ETSource directory, and to the directory in which
# to write the ActiveDocuments. This is done using Rake arguments:
#
#   rake import[../etsource,../etdata]
#
# Note that the arguments must not contain spaces. If you need to use spaces,
# wrap the full rake task name in quotes:
#
#   rake 'import[../My ETSource Repo,../My ETData Repo]'
#
# If the paths provided are not absolute, they are assumed to be relative to
# the ETLib root.
namespace :import do
  # Returns a hash where each key is the name of the sector, and the value is
  # an array containing all the nodes in that sector.
  def nodes_by_sector
    nodes = YAML.load_file($from_dir.join('topology/export.graph'))
    nodes = nodes.with_indifferent_access

    Dir.glob($from_dir.join('datasets/nl/graph/**.yml')).each do |file|
      YAML.load_file(file).each do |key, properties|
        nodes[key].merge!(properties) if nodes[key]
      end
    end

    nodes.group_by { |key, data| data['sector'] || 'nosector' }
  end

  # Given a node key and its data, determines which subclass of Node should
  # be used.
  def node_subclass(key, data)
    return Tome::Node::FinalDemand if key.to_s.match(/final_demand/)
    return Tome::Node::Demand      if key.to_s.match(/demand/)

    out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }
    in_slots.map!  { |slot| match = slot.match(/\((.*)\)/) ; match[1] }
    out_slots.map! { |slot| match = slot.match(/\((.*)\)/) ; match[1] }

    if ((in_slots - ['loss']) - (out_slots - ['loss'])).any?
      # A node is a converter if it outputs energy in a different carrier than
      # it received; the exception being loss which we ignore.
      Tome::Node::Converter
    else
      Tome::Node
    end
  end

  # Returns a hash containing all the queries defined in the data/import CSVs.
  # Includes queries for nodes, edges, and slots.
  def queries
    @queries ||= begin
      queries = {}

      Pathname.glob($from_dir.join('data/import/**/*.csv')).each do |path|
        data = CSV.table(path).select do |row|
          row[:status].nil? || row[:status] == 'necessary'
        end

        data.each do |row|
          if row[:converter_key]
            key = row[:converter_key].to_sym
          else
            key = Tome::Edge.key(row[:from], row[:to], row[:carrier])
          end

          queries[key] = row[:query]
        end
      end

      queries
    end
  end

  # Figures out a path given by the user, and ensures that the directory
  # specified exists.
  #
  # Returns a Pathname.
  def dir(path)
    path = Pathname.new(path)
    path = Tome.root.join(path) if path.relative?

    unless path.directory?
      raise "No directory found at #{ path.to_s }"
    end

    path
  end

  # Used to nicely format the progress of an import.
  #
  # Create a new Import run with a message indicating the "type of thing"
  # being imported, and wrap each imported thing in Runner#item. For example:
  #
  #   runner = ImportRun.new('nodes')
  #   nodes.each { |node| runner.item { process node } }
  #   runner.finish
  #
  # The class will catch any RuntimeErrors which are raised, and report all
  # the failures at the end (when you call +finish+).
  class ImportRun
    def initialize(message)
      @message  = message
      @errors   = []

      @reporter = Tome::Term::Reporter.new("Importing #{ message }",
        imported: :green, failed: :red, skipped: :yellow)
    end

    # Wrap each single imported item in this method, to record the success or
    # failure.
    def item
      if thing = yield
        thing.save(false)
        @reporter.inc(:imported)
      else
        @reporter.inc(:skipped)
      end
    rescue RuntimeError => ex
      @reporter.inc(:failed)
      @errors.push(ex)
    end

    # Prints out error messages, if there were any.
    def finish
      puts ''
      @errors.each { |error| puts error.message ; puts }
    end
  end # ImportRun

  # --------------------------------------------------------------------------

  # Loads Tome.
  task :setup, [:from, :to] do |_, args|
    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    require 'fileutils'
    require 'tome'
    require 'term/ansicolor'
    require 'active_support/core_ext/hash/indifferent_access'

    if args.from.nil?
      raise "You did not specify a 'from' directory!"
    end

    if args.to.nil?
      raise "You did not specify a 'to' directory!"
    end

    $from_dir     = dir(args.from)
    Tome.data_dir = dir(args.to)
  end # task :setup

  task all: [:carriers, :nodes, :edges, :presets]
end # namespace :import

desc 'Import edges and nodes from the old format to ActiveDocument'
task :import, [:from, :to] => ['import:all']
