module Atlas

  # This class contains the EnergyBalance of a certain Area.
  # The EnergyBalance contains per energy carrier how much is produced
  # tranformed, used (finaly demand) etc.
  #
  # Currently, it is presumed that the EnergyBalance values are provided
  # in ktoe, the standard of the IEA.
  class EnergyBalance < CSVDocument
    ORIGINAL_UNIT = :tj

    attr_accessor :key, :unit

    def initialize(key = :nl, unit = :tj)
      @key  = key
      @unit = unit

      dataset = Dataset.find(key)

      # Always prefer a file from the dataset itself before falling back to the parent.
      if (option = dataset.dataset_dir.join('energy_balance.open_access.csv')).exist?
        super(option)
      elsif (option = dataset.dataset_dir.join('energy_balance.csv')).exist?
        super(option)
      elsif (option = dataset.path_resolver.join('energy_balance.open_access.csv')).exist?
        super(option)
      else
        super(dataset.path_resolver.join('energy_balance.csv'))
      end
    end

    # Loads a stored energy balance
    def self.find(key, year = nil)
      key ? new(key) : fail(InvalidKeyError.new(key))
    end

    # Returns the energy balance item in the correct unit
    def get(use, carrier)
      convert_to_unit(super(use, carrier))
    end

    # basicly the same as get, but then in one big string, separates by comma
    # @ return [Float]
    def query(string)
      params = string.split(',')
      get(params.first, params.last)
    end

    private

    # Internal: Given a value extracted from the CSV file, converts it to the
    # unit used by the EnergyBalance instance.
    #
    # Returns a numeric, warning if the given value was not also numeric.
    def convert_to_unit(value)
      if value.is_a?(Numeric)
        EnergyUnit.new(value, ORIGINAL_UNIT).to_unit(unit)
      else
        puts "WARNING: Discarding non-numeric #{ value.inspect }"
        0.0
      end
    end
  end
end
