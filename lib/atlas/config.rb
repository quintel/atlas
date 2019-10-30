# frozen_string_literal: true

module Atlas
  # Reads YAML config files from the "config" directory.
  module Config
    class << self
      # Public: Reads a YAML config file from the ETSource config directory.
      #
      # basename - The name of the config file, minus the ".yml" extension.
      def read(basename)
        YAML.load_file(path_for_basename(basename))
      rescue Errno::ENOENT
        raise DocumentNotFoundError.new(clean_basename(basename), self)
      end

      # Internal: Reads a YAML config file from the ETSource config directory,
      # returning nil if it isn't readable.
      #
      # See Config.read
      def read?(basename)
        if (path = path_for_basename(basename)).file?
          YAML.load_file(path)
        end
      end

      private

      def path_for_basename(basename)
        Atlas.data_dir.join('config').join("#{clean_basename(basename)}.yml")
      end

      def clean_basename(basename)
        basename.to_s.downcase.gsub(/[^a-z0-9_]/, '')
      end
    end
  end
end
