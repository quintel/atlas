# frozen_string_literal: true

module Atlas
  class Dataset
    # Contains one or more `EmissionsDocument`s (one per year) belonging to a `Dataset`.
    class EmissionsCollection
      # Public: Given a path to a directory containing emissions CSV files,
      # instantiates the EmissionsDocument instances and returns a collection.
      #
      # dir - Pathname to emissions directory
      #
      # Returns an EmissionsCollection.
      def self.at_path(dir)
        emissions_by_year = load_emissions_files(dir)
        new(emissions_by_year)
      end

      # Public: Creates a new collection of `EmissionsDocument`s.
      #
      # emissions_by_year - Hash of year symbols to EmissionsDocument instances
      #
      # Returns an EmissionsCollection.
      def initialize(emissions_by_year)
        @emissions_by_year = emissions_by_year
      end

      # Public: Returns the EmissionsDocument for the given year, or nil.
      #
      # year - Symbol or Integer representing the year (:default, 1990, etc.)
      #
      # Returns an EmissionsDocument or nil.
      def get(year = :default)
        @emissions_by_year[year.to_sym]
      end

      # Public: Returns the EmissionsDocument for the given year, or raises.
      #
      # year - Symbol or Integer representing the year
      #
      # Returns an EmissionsDocument.
      # Raises MissingEmissionsYearError if year not found.
      def get!(year)
        get(year) || raise(MissingEmissionsYearError.new(year, years))
      end

      # Public: Returns the default year EmissionsDocument.
      def default
        get(:default)
      end

      # Public: Returns all emissions data as a flat hash.
      # Merges all years, adding year suffix for non-default years.
      #
      # Returns Hash like {households_energetic_co2: 12.0, households_energetic_co2_1990: 10.0}
      def to_hash
        @emissions_by_year.each_with_object({}) do |(year, doc), result|
          doc.to_hash.each do |key, value|
            suffix = year == :default ? '' : "_#{year}"
            result[:"#{key}#{suffix}"] = value
          end
        end
      end

      # Public: Returns array of available years as symbols.
      def years
        @emissions_by_year.keys
      end

      private

      # Internal: Loads all emission files from directory.
      def self.load_emissions_files(dir)
        default_file = dir.join('emissions_default.csv')
        emissions = {}

        emissions[:default] = load_file(default_file) if default_file.file?

        Dir.glob(dir.join('emissions_*.csv').to_s).sort.each do |path_str|
          year_sym = extract_year_from_filename(path_str)
          emissions[year_sym] = load_file(Pathname(path_str)) if year_sym
        end

        emissions
      end

      # Internal: Extracts year symbol from filename.
      def self.extract_year_from_filename(path)
        filename = File.basename(path, '.csv')
        return nil if filename == 'emissions_default'

        filename.match(/^emissions_(\d+)$/)&.captures&.first&.to_sym
      end

      # Internal: Loads a single emissions file.
      def self.load_file(path)
        CSVDocument::EmissionsDocument.read(path, index_size: 4)
      end

      private_class_method :load_emissions_files, :extract_year_from_filename,
                           :load_file
    end
  end
end
