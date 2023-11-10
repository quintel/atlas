# frozen_string_literal: true

module Atlas
  # Reads YAML config files from the "config" directory.
  module Config
    class << self
      # Public: Reads a YAML config file from the ETSource config directory.
      #
      # basename - The name of the config file, minus the ".yml" extension.
      def read(basename)
        read?(basename) ||
          raise(ConfigNotFoundError, path_for_basename(basename))
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
        path_with_subfolder(Atlas.data_dir.join('config'), basename)
      end

      def clean_basename(basename)
        basename.to_s.downcase.gsub(/[^a-z0-9_]/, '')
      end

      def path_with_subfolder(path, basename)
        with_subfolder = basename.to_s.split('.')

        if with_subfolder.length == 2
          basename = with_subfolder[1]
          path = path.join(with_subfolder[0])
        end

        path.join("#{clean_basename(basename)}.yml")
      end
    end
  end
end
