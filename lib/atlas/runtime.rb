module Atlas
  class Runtime < ::Rubel::Base
    attr_reader :dataset

    # Creates a new runtime in the +context+ of a dataset.
    def initialize(dataset, graph)
      @dataset = dataset
      @graph   = graph
      super()
    end

    # Public: Executes a query. This is idential to Rubel's +execute+ method
    # except that we remove the "rescue" block since it unnecessarily catches
    # and re-raises errors with the generic RuntimeError and truncates
    # backtraces.
    #
    # Returns the result of the query.
    def execute(string)
      if string.is_a?(::String)
        instance_exec(&sanitized_proc(string))
      else
        instance_exec(&string)
      end
    rescue StandardError, ScriptError => ex
      raise QueryError.new(ex, string)
    end

    alias query execute

    # Query Functions --------------------------------------------------------

    # Public: Takes a value from the EnergyBalance for the current Dataset.
    #
    # Returns an object.
    def EB(use, carrier)
      energy_balance.get(use, carrier)
    end

    # Public: Gets a property from the current Area.
    #
    # Returns an object.
    def AREA(property)
      dataset.send(property)
    end

    # Public: Retrieves a share value identified by the given key.
    #
    # file_key  - The name of the file in which to find the share value, minus
    #             the ".csv" extension.
    # attribute - The name of the attribute to be extracted from the share
    #             file.
    #
    # For example, retrieving the gasoline share from trucks.csv.
    #
    #   SHARE(:trucks, :gasoline)
    #
    # Returns a Numeric, or raises NoSuchShareError if the file or attribute
    # do not exist.
    def SHARE(file_key, attribute)
      dataset.shares(file_key).get(attribute)
    end

    # Public: Retrieves a pre-set demand for a CHP node from the chp.csv file.
    #
    # node_key - The key of the node whose demand is to be retrieved.
    #
    # For example, retrieving the demand of a node with the key "agri_chp".
    #
    #   CHP(:agri_chp)
    #
    # Returns a numeric.
    def CHP(node_key)
      dataset.chps.get(node_key)
    end

    # Public: Given the key of a node, retrieves the production (energy
    # supplied) of the node from the central_producers.csv file.
    #
    # node_key - The key of the node whose production is to be fetched.
    #
    # Returns a Float.
    def CENTRAL_PRODUCTION(node_key)
      dataset.central_producers.get(node_key, :demand)
    end

    # Public: Given the key of a node, retrieves the production (energy
    # supplied) of the node from the primary_producers.csv file.
    #
    # node_key - The key of the node whose production is to be fetched.
    #
    # Returns a Float.
    def PRIMARY_PRODUCTION(node_key)
      dataset.primary_production.get(node_key, :demand)
    end

    # Public: Given a key from the time curves file, retrieves the associated
    # value.
    #
    # Presently just a stub so that queries using it don't break. This will
    # be implemented soon.
    #
    # key - The key identifying the row to be read.
    #
    # Returns a Float.
    def TIME_CURVE(*)
      0.0
    end

    # Public: Given keys to look up a node or edge, retrieves the demand
    # attribute of the object.
    #
    # *keys - Keys used to identify the node or edge.
    #
    # Returns a numeric.
    def DEMAND(*keys)
      lookup(*keys).get(:demand)
    end

    # Public: Given keys to look up an edge, retrieves the value of the edge's
    # :parent_share attribute.
    #
    # parent_key - The key of the parent node.
    # child_key  - The key of the child node.
    # carrier    - The name of the carrier.
    #
    # Returns a numeric.
    def PARENT_SHARE(parent_key, child_key, carrier)
      lookup(parent_key, child_key, carrier).get(:parent_share)
    end

    # Public: Given keys to look up an edge, retrieves the value of the edge's
    # :child_share attribute.
    #
    # parent_key - The key of the parent node.
    # child_key  - The key of the child node.
    # carrier    - The name of the carrier.
    #
    # Returns a numeric.
    def CHILD_SHARE(parent_key, child_key, carrier)
      lookup(parent_key, child_key, carrier).get(:child_share)
    end

    #######
    private
    #######

    # Helpers ----------------------------------------------------------------

    # Internal: The EnergyBalance data for the datasets region.
    #
    # Returns an EnergyBalance.
    def energy_balance
      dataset.energy_balance
    end

    # Internal: Retrieves a Node by it's key, or an edge by the key of the
    # parent node, child node, and carrier.
    #
    # keys* - One or more keys.
    #
    # Returns the Turbine::Node or Turbine::Edge. Raises
    def lookup(*keys)
      keys = keys.map(&:to_sym)

      if keys.one?
        # A single key looks up a node by its key.
        @graph.node(keys.first) || raise(UnknownNodeError.new(keys.first))
      elsif keys.length == 3
        # Three keys looks up an edge by its parent and child node keys, and
        # the name of the carrier.

        # Assert that both nodes exist.
        parent = lookup(keys[0])
        child  = lookup(keys[1])

        parent.out_edges(keys.last).detect do |edge|
          edge.to.key == keys[1]
        end || raise(UnknownEdgeError.new(keys))
      else
        # Any other number of keys is invalid.
        raise InvalidLookupError.new(keys)
      end
    end

  end # Runtime
end # Atlas
