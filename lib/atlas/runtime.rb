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
        instance_exec(&::Rubel.sanitized_proc(string))
      else
        instance_exec(&string)
      end
    rescue ::StandardError, ::ScriptError => ex
      ::Kernel.raise(QueryError.new(ex, string))
    end

    alias_method :query, :execute

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

    # Public: Retrieves an efficiency, typically assigned as a slot share
    # ("conversion") from the given file and carrier.
    #
    # file_key  - The name of the file in which the efficiency is stored.
    # direction - The direction of the slot, "input" or "output".
    # carrier   - The name of the carrier.
    #
    # For example
    #
    #   ~ output.coal = EFFICIENCY(transformation_coal, output, coal)
    #
    # Returns a number.
    def EFFICIENCY(file_key, direction, carrier)
      direction == :input  if direction == :in
      direction == :output if direction == :out

      dataset.efficiencies(file_key).get("#{ direction }.#{ carrier }")
    end

    # Public: Given the key of a node, retrieves the production (energy
    # supplied) of the node from the central_producers.csv file.
    #
    # node_key - The key of the node whose production is to be fetched.
    #
    # Returns a Float.
    def CENTRAL_PRODUCTION(node_key, attribute = :demand)
      dataset.central_producers.get(node_key, attribute)
    end

    # Public: Given the key of a node, retrieves the production (energy
    # supplied) of the node from the primary_producers.csv file.
    #
    # node_key - The key of the node whose production is to be fetched.
    #
    # Returns a Float.
    def PRIMARY_PRODUCTION(node_key, attribute)
      dataset.primary_production.get(node_key, attribute)
    end

    def PARENT_VALUE(node_key, attribute)
      dataset.parent_values.get(node_key, attribute)
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
    def TIME_CURVE(curve_key, attribute)
      dataset.time_curve(curve_key).get(@dataset.analysis_year, attribute)
    end

    # Public: Retrieves a demand value identified by the given key.
    #
    # file_key  - The name of the file in which to find the demand value, minus
    #             the ".csv" extension.
    # attribute - The name of the attribute to be extracted from the demand
    #             file.
    #
    # For example, retrieving the gasoline share from trucks.csv.
    #
    #   DEMAND(:industry, :final_demand_coal_gas)
    #
    # Returns a Numeric.
    def DEMAND(file_key, attribute)
      dataset.demands(file_key).get(attribute)
    end

    # Public: Retrieves a value from an FCE file.
    #
    # file_key  - The name of the FCE file to read.
    # carrier   - The carrier whose data to read.
    # attribute - The attribute to be read.
    #
    # For example, if there exists a carrier file "bio_ethanol.yml" with the
    # following data:
    #
    #   :sugar_beets:
    #     :co2_conversion_per_mj: 0.0
    #     :start_value: 0.6
    #   :sugar_cane:
    #     :co2_conversion_per_mj: 0.0
    #     :start_value: 0.4
    #
    # Retrieving the sugar beets start value would be achieved by calling:
    #
    #   FCE(bio_ethanol, sugar_beets, start_value)
    #
    # Returns a numeric.
    #
    # Raises Errno::ENOENT if the file does not exist or KeyError if the carrier
    # or attribute does not exist.
    def FCE(file_key, carrier, attribute)
      dataset.fce(file_key).fetch(carrier.to_sym).fetch(attribute.to_sym)
    end

    private

    # Helpers ----------------------------------------------------------------

    # Internal: The EnergyBalance data for the datasets region.
    #
    # Returns an EnergyBalance.
    def energy_balance
      dataset.energy_balance
    end

  end # Runtime
end # Atlas
