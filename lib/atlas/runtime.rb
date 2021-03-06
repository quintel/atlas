# frozen_string_literal: true

module Atlas
  # Runtime in which we execute queries for dynamic attributes.
  #
  # Rubel::Runtime::Sandbox inherits from BasicObject, so many normally-global
  # methods need to reference `::Kernel` explicitly.
  class Runtime < ::Rubel::Runtime::Sandbox
    include ::Rubel::Functions::Defaults

    # Queries must return a numeric value, or one of these.
    PERMITTED_NON_NUMERICS = [nil, :infinity, :recursive].freeze

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

    # Public: Much like `execute`, but raises a useful error if the query
    # returns a non-numeric, or unexpected, value.
    #
    # Returns the result of the query.
    def execute_checked(string)
      result = execute(string)

      unless result.is_a?(::Numeric) || PERMITTED_NON_NUMERICS.include?(result)
        ::Kernel.raise(NonNumericQueryError.new(result))
      end

      result == :infinity ? ::Float::INFINITY : result
    rescue ::RuntimeError => e
      e.message.gsub!(/$/, " (executing: #{string.inspect})")
      ::Kernel.raise(e)
    end

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
      dataset.public_send(property)
    end

    # Public: Fetches a value from the carriers.csv file. If the file defines no such value, or the
    # value is nil, the value is looked up from the ActiveDocument instead.
    #
    # carrier_key - The name of the carrier.
    # attr_key    - The name of the attribute to be fetched.
    #
    # For example:
    #   CARRIER(:coal, :co2_conversion_per_mj)
    #
    # Returns a float.
    def CARRIER(carrier_key, attr_key)
      dataset.carriers.get(carrier_key, attr_key) ||
        Atlas::Carrier.find(carrier_key).public_send(attr_key)
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

    def PARENT_VALUE(node_key, attribute)
      dataset.parent_values.get(node_key, attribute)
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

    private

    # Helpers ----------------------------------------------------------------

    # Internal: The EnergyBalance data for the datasets region.
    #
    # Returns an EnergyBalance.
    def energy_balance
      dataset.energy_balance
    end
  end
end
