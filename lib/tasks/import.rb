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
    return ETSource::FinalDemandNode if key.to_s.match(/final_demand/)
    return ETSource::DemandNode      if key.to_s.match(/demand/)

    out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }
    in_slots.map!  { |slot| match = slot.match(/\((.*)\)/) ; match[1] }
    out_slots.map! { |slot| match = slot.match(/\((.*)\)/) ; match[1] }

    if ((in_slots - ['loss']) - (out_slots - ['loss'])).any?
      # A node is a converter if it outputs energy in a different carrier than
      # it received; the exception being loss which we ignore.
      ETSource::Converter
    else
      ETSource::Node
    end
  end

  # Returns a hash containing all the queries defined in the data/import CSVs.
  # Includes queries for nodes, edges, and slots.
  def queries
    @queries ||= begin
      queries = {}

      Pathname.glob(ETSource.data_dir.join('import/**/*.csv')).each do |path|
        data = CSV.table(path).select do |row|
          row[:status].nil? || row[:status] == 'necessary'
        end

        data.each do |row|
          if row[:converter_key]
            key = row[:converter_key].to_sym
          else
            key = ETSource::Edge.key(row[:from], row[:to], row[:carrier])
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
    path = ETSource.root.join(path) if path.relative?

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
      @message = message
      @errors  = []
      @printed = false
    end

    # Wrap each single imported item in this method, to record the success or
    # failure.
    def item
      unless @printed
        # Print the initial message if this is the first item to be imported.
        print "Processing #{ @message }: "
        @printed = true
      end

      document = yield
      document.save(false)

      unless document.valid?
        raise InvalidDocumentError.new(document)
      end

      print Term::ANSIColor.green { '.' }
    rescue RuntimeError => ex
      print Term::ANSIColor.red { '!' }
      @errors.push(ex)
    end

    # Prints out error messages, if there were any.
    def finish
      puts '' ; puts ''
      @errors.each { |error| puts error.message ; puts }
    end
  end # ImportRun

  # --------------------------------------------------------------------------

  # Loads ETSource.
  task :setup, [:from, :to] do |_, args|
    $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

    require 'fileutils'
    require 'etsource'
    require 'term/ansicolor'
    require 'active_support/core_ext/hash/indifferent_access'

    $from_dir         = dir(args.from)
    ETSource.data_dir = dir(args.to)
  end # task :setup

  # --------------------------------------------------------------------------

  desc <<-DESC
    Import nodes from the old format to ActiveDocument.

    Reads the legacy export.graph file and the "nl" dataset, and creates
    new-style ActiveDocument files for each node.

    This starts by *deleting* everything in data/nodes on the assumption that
    there are no hand-made changes.
  DESC
  task :nodes, [:to, :from] => [:setup] do |_, args|
    include ETSource

    # Wipe out *everything* in the nodes directory; rather than simply
    # overwriting existing files, since some may have new naming conventions
    # since the previous import.
    FileUtils.rm_rf(ETSource::Node.directory)

    runner = ImportRun.new('nodes')

    nodes_by_sector.each do |sector, nodes|
      nodes.each do |key, data|
        runner.item do
          unless data['slots']
            raise RuntimeError.new("Node #{ key.inspect } has no slots?!")
          end

          klass = node_subclass(key, data)

          # Split the original slots array into two, containing the outgoing
          # and incoming slots respectively. This is done by recognising that
          # outgoing slots begin with the carrier key in (brackets).
          out_slots, in_slots = data['slots'].partition { |s| s.match(/^\(/) }

          data[:in_slots]  = in_slots.map  { |s| s.match(/\((.*)\)/)[1] }
          data[:out_slots] = out_slots.map { |s| s.match(/\((.*)\)/)[1] }

          data.delete('links')
          data.delete('slots')

          data[:query] = queries[key.to_sym] if queries.key?(key.to_sym)
          data[:path]  = "#{ sector }/#{ key }"

          klass.new(data)
        end
      end
    end

    runner.finish
  end # task :nodes

  # --------------------------------------------------------------------------

  desc <<-DESC
    Import edges from the old format to ActiveDocument.

    This starts by *deleting* everything in data/edges on the assumption that
    there are no hand-made changes.
  DESC
  task :edges, [:from, :to] => [:setup] do |_, args|
    include ETSource

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

          props = { path: path, type: type, reversed: ! data[:reversed].nil? }

          if queries.key?(key.to_sym)
            # For the moment, assume shares are technology shares.
            props[:sets]  = :parent_share
            props[:query] = queries[key.to_sym] if queries.key?(key.to_sym)
          end

          Edge.new(props)
        end
      end
    end # nodes_by_sector.each

    runner.finish
  end # task :edges

  # --------------------------------------------------------------------------

  desc <<-DESC
    Import edges from the old format to ActiveDocument.

    This starts by *deleting* everything in data/edges on the assumption that
    there are no hand-made changes.
  DESC
  task :presets, [:from, :to] => [:setup] do |_, args|
    include ETSource

    # Wipe out *everything* in the presets directory.
    FileUtils.rm_rf(Preset.directory)

    original_dir = $from_dir.join('presets')
    runner       = ImportRun.new('presets')

    Pathname.glob(original_dir.join('**/*.yml')) do |path|
      runner.item do
        relative = path.relative_path_from(original_dir)
        hash     = YAML.load_file(path)
        doc_path = relative.to_s.gsub(/\.yml$/, '')

        Preset.new(hash.merge(path: doc_path))
      end
    end

    runner.finish
  end # :presets

  # --------------------------------------------------------------------------

  task all: ['import:nodes', 'import:edges', 'import:presets'] do
  end # task :all
end # namespace :import

desc 'Import edges and nodes from the old format to ActiveDocument'
task :import, [:from, :to] => ['import:all']
