module Atlas
  class LoadProfile
    attr_reader :path

    def initialize(path)
      @path = path
    end

    def values
      @values ||= YAML.load_file(@path)
    end
  end # Load Profile
end # Atlas
