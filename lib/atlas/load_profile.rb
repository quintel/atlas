module Atlas
  class LoadProfile

    DIRECTORY = 'load_profiles'

    def initialize(path)
      @yaml = YAML.load_file full_path(path)
    end

    def values
      @yaml
    end

    #######
    private
    #######

    def full_path(path)
      Atlas.data_dir.join(DIRECTORY, path)
    end

  end # Load Profile
end # Atlas
