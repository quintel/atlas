module Atlas

  # This class contains the EnergyBalance of a certain Area.
  # The EnergyBalance contains per energy carrier how much is produced
  # tranformed, used (finaly demand) etc.
  #
  # Currently, it is presumed that the EnergyBalance values are provided
  # in ktoe, the standard of the IEA.
  class EnergyBalance < CSVDocument
    # Public: Loads a stored energy balance
    def self.find(key)
      dataset = Dataset.find(key)

      # Always prefer a file from the dataset itself before falling back to the parent.
      if (option = dataset.dataset_dir.join('energy_balance.open_access.csv')).exist?
        read(option)
      elsif (option = dataset.dataset_dir.join('energy_balance.csv')).exist?
        read(option)
      elsif (option = dataset.path_resolver.join('energy_balance.open_access.csv')).exist?
        read(option)
      elsif (option = dataset.path_resolver.join('energy_balance.gpg')).exist?
        from_string(decrypt(option), option)
      else
        read(dataset.path_resolver.join('energy_balance.csv'))
      end
    end

    # Don't use `new` directly, use `find` instead.
    private_class_method :new

    # Internal: Decrypts an energy balance at the given path, returning the CSV contents as string.
    #
    # Returns a string.
    def self.decrypt(path)
      GPGME::Crypto.new(password: Atlas.password).decrypt(
        File.read(path),
        pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK
      ).to_s
    end

    private_class_method :decrypt

    # Returns the energy balance item as a numeric, or logs a message and returns zero.
    def get(use, carrier)
      if (value = super).is_a?(Numeric)
        value.to_f
      else
        raise AtlasError,
          "Non-numeric energy balance value #{use.inspect} #{carrier.inspect} in #{@path}.inspect"
      end
    end

    # basicly the same as get, but then in one big string, separates by comma
    # @ return [Float]
    def query(string)
      params = string.split(',')
      get(params.first, params.last)
    end
  end
end
