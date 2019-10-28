# frozen_string_literal: true

module Atlas
  module Config
    # Public: Reads a YAML config file from the ETSource config directory.
    #
    # basename - The name of the config file, minus the ".yml" extension.
    def self.read(basename)
      basename = basename.to_s.downcase.gsub(/[^a-z0-9_]/, '')
      YAML.load_file(Atlas.data_dir.join('config').join("#{basename}.yml"))
    rescue Errno::ENOENT
      raise DocumentNotFoundError.new(basename, self)
    end
  end
end
