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
  LINK_RE = /
    (?<consumer>[\w_]+)-       # Child node key
    \([^)]+\)\s                # Carrier key (ignored)
    (?<reversed><)?            # Arrow indicating a reversed link?
    --\s(?<type>\w)\s-->?\s    # Link type and arrow
    \((?<carrier>[^)]+)\)-     # Carrier key
    (?<supplier>[\w_]+)        # Parent node key
  /xi

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

  # Returns a hash containing data about edges from the NL dataset'
  def edge_data
    @edges ||= begin
      data = {}

      Dir.glob($from_dir.join('datasets/nl/graph/**.yml')).each do |file|
        YAML.load_file(file).each do |key, properties|
          if key.to_s.match(LINK_RE) && properties['priority']
            data[key] = { priority: properties['priority'] }
          end
        end
      end

      data
    end
  end

  # Given a node key and its data, determines which subclass of Node should
  # be used.
  def node_subclass(key, data)
    if central_producers.include?(key.to_sym)
      return Atlas::Node::CentralProducer
    end

    return Atlas::Node::FinalDemand if key.match(/final_demand/)
    return Atlas::Node::Demand      if key.match(/demand/)

    out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }
    in_slots.map!  { |slot| match = slot.match(/\((.*)\)/) ; match[1] }
    out_slots.map! { |slot| match = slot.match(/\((.*)\)/) ; match[1] }

    if ((in_slots - ['loss']) - (out_slots - ['loss'])).any?
      # A node is a converter if it outputs energy in a different carrier than
      # it received; the exception being loss which we ignore.
      Atlas::Node::Converter
    else
      Atlas::Node
    end
  end

  # Returns an array containing the keys of all nodes in the central producers
  # CSV file.
  def central_producers
    @producers ||= CSV.table(
      Atlas.data_dir.join('datasets/nl/central_producers.csv')
    ).map { |row| row[:key].to_sym }
  end

  # Returns a hash containing all the queries defined in the data/import CSVs.
  # Includes queries for nodes, edges, and slots.
  def queries
    @queries ||= begin
      queries = Hash.new { |hash, key| hash[key] = [] }

      Atlas::Node.all.select { |n| n.queries.any? }.each do |node|
        node.queries.each do |attribute, query|
          queries[node.key].push(
            key: node.key, attribute: attribute, query: query)
        end
      end

      Atlas::Edge.all.select { |e| e.queries.any? }.each do |edge|
        edge.queries.each do |attribute, query|
          queries[edge.key].push(
            key: edge.key, attribute: attribute, query: query)
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
    path = Atlas.root.join(path) if path.relative?

    unless path.directory?
      fail "No directory found at #{ path.to_s }"
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

      @reporter = Atlas::Term::Reporter.new("Importing #{ message }",
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

  # Loads Atlas.
  task :setup, [:from, :to] do |_, args|
    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    require 'fileutils'
    require 'atlas'
    require 'term/ansicolor'
    require 'active_support/core_ext/hash/indifferent_access'

    if args.from.nil?
      fail "You did not specify a 'from' directory!"
    end

    if args.to.nil?
      fail "You did not specify a 'to' directory!"
    end

    $from_dir     = dir(args.from)
    Atlas.data_dir = dir(args.to)
  end # task :setup

  task all: [:carriers, :nodes, :edges, :presets]
end # namespace :import

desc 'Import edges and nodes from the old format to ActiveDocument'
task :import, [:from, :to] => ['import:all']
