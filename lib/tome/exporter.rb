module Tome
  # Given a fully calculated graph, exports the demand and share data so that
  # it can be used by Tome's production mode (in ETEngine).
  class Exporter
    # Public: Creates a new exporter. Does not check that the graph has been
    # calculated; it is expected you'll run the graph through Runner first,
    # which will raise errors if the graph is not fully calculated.
    #
    # graph - The graph which will be exported.
    #
    # Returns an Exporter.
    def initialize(graph)
      @graph = graph
    end

    # Public: Writes the calculated values in the graph to CSV files in the
    # given directory.
    #
    # dir - Path to the directory in which to write the CSV files.
    #
    # Returns nothing.
    def export_to(dir)
      FileUtils.mkdir_p(dir)

      export_nodes(data[:nodes], dir.join('nodes.csv'))
      export_edges(data[:edges], dir.join('edges.csv'))
      export_slots(data[:slots], dir.join('slots.csv'))

      nil
    end

    #######
    private
    #######

    # Internal: Extracts from the graph collections containing all the nodes,
    # edges, and slots.
    #
    # Returns a Hash.
    def data
      @data ||= { nodes:[], edges: [], slots: [] }.tap do |hash|
        @graph.nodes.each do |node|
          hash[:nodes].push(node)
          hash[:edges].push(*node.out_edges.to_a)
          hash[:slots].push(*node.slots.in.to_a)
          hash[:slots].push(*node.slots.out.to_a)
        end
      end
    end

    # Internal: Given an array of +nodes+, and a +path+ to which to write,
    # creates a CSV containing all of the node demands.
    #
    # Returns nothing.
    def export_nodes(nodes, path)
      write(nodes, path, key: ->(n) { n.key }, demand: ->(n) { n.demand })
    end

    # Internal: Given an array of +edges+, and a +path+ to which to write,
    # creates a CSV containing all of the edge shares.
    #
    # Returns nothing.
    def export_edges(edges, path)
      write(edges, path, {
        key: ->(e) { Tome::Edge.key(e.parent.key, e.child.key, e.label) },
        child_share: ->(e) { e.child_share }
      })
    end

    # Internal: Given an array of +slots+, and a +path+ to which to write,
    # creates a CSV containing all of the slot shares.
    #
    # Returns nothing.
    def export_slots(slots, path)
      write(slots, path, {
        key: ->(s) { Tome::Slot.key(s.node.key, s.direction, s.carrier) },
        share: ->(s) { s.share }
      })
    end

    # Internal: Formats a +value+ for storage in a CSV file.
    #
    # Returns a string.
    def format(value)
      case value
        when nil     then ''
        when Numeric then '%.10f' % value
        else              value.to_s
      end
    end

    # Internal: Writes a +collection+ of things to a CSV at +path+, using the
    # hash of attributes to determine the value of each column, for each
    # element in the collection.
    #
    # For example
    #
    #   write([...], path, {
    #     key: ->(thing) { thing.key },
    #     id:  ->(thing) { UUID.generate(thing) }
    #   })
    #
    # Returns nothing.
    def write(collection, path, attributes)
      procs = attributes.values.map { |getter| getter.to_proc }

      body = collection.map do |element|
        procs.map { |getter| format(getter.call(element)) }.join(',')
      end

      path.open('w') do |file|
        file.write("#{ attributes.keys.join(',') }\n")
        file.write(body.join("\n"))
      end
    end
  end # Exporter
end # Tome
