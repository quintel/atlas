module Atlas
  class CSVDocument
    attr_reader :path
    attr_reader :table

    # Columns called "year" will be converted to an integer.
    YEAR_NORMALIZER = lambda do |value, info|
      info.header == :year ? value.to_f.to_i : value
    end

    class << self
      # Public: Reads a CSV file whose contents is a simple list of values with
      # no headers.
      #
      # Returns an Array.
      def curve(path)
        CSV.read(path.to_s, converters: [YEAR_NORMALIZER, :float]).map(&:first).compact
      end

      # Public: Reads a CSV at the given path.
      def read(path, **opts)
        new(CSV.read(path, **table_opts), path, **opts)
      end

      # Public: Reads a CSV from a string.
      def from_string(str, path = nil, **opts)
        new(CSV.parse(str, **table_opts), path, **opts)
      end

      # Public: Creates a new CSVDocument with the given headers.
      def empty(headers, path, **opts)
        path = Pathname(path) unless path.nil?

        raise(ExistingCSVHeaderError, path) if path&.file?

        headers = headers.map { |header| normalize_key(header) }
        new(CSV::Table.new([CSV::Row.new(headers, headers, true)]), path, **opts)
      end

      # Internal: Converts the given key to a format which removes all special
      # characters.
      #
      # Returns a Symbol.
      def normalize_key(key)
        case key
        when Numeric, nil
          # nils never happen here in Ruby >= 2.3 since nils
          # skip the normalizer.
          key
        else
          key.to_s.downcase.strip
            .gsub(/(?:\s+|-)/, '_')
            .gsub(/[^a-zA-Z0-9_]+/, '')
            .squeeze('_')
            .gsub(/_$/, '')
            .to_sym
        end
      end

      private

      # Internal: Default options when parsing to a CSV::Table.
      def table_opts
        {
          converters: [YEAR_NORMALIZER, :float],
          headers: true,
          header_converters: [->(header) { normalize_key(header) }],
          # Needed to retrieve the headers in case of an otherwise empty csv file
          return_headers: true
        }
      end

      # Internal: Procs passed to the CSV::Table describing how to convert values
      # from the CSV to Ruby types.
      #
      # Returns an Array of Procs or Symbols.
      def value_converters
        [YEAR_NORMALIZER, :float]
      end
    end

    # Use `read`, `from_string`, or `empty`.
    private_class_method :new

    # Internal: Creates a new CSV document instance which will read data from a CSV file on disk.
    # Documents are read-write.
    #
    # `new` is not available; use `read`, `from_string`, or `empty`.
    #
    # table - A CSV::Table with the data.
    # path  - An optional path to the CSV file.
    #
    # Returns a CSVDocument.
    def initialize(table, path = nil)
      @headers = table.headers
      @path = Pathname(path) if path
      @table = table

      # Delete the header row for the internal representation. This will be (re-)created when saved.
      @table.delete(0)

      raise(BlankCSVHeaderError, path || '<no path>') if @headers.any?(&:nil?)
    end

    # Public: Saves the CSV document to disk
    #
    # follow_link - If the path is a symlink, the file will be saved at the
    #               symlink target location. Setting `follow_link` to false
    #               will remove the symlink and replace it with a file
    #               containing the CSV contents; the original linked file will
    #               be unchanged.
    #
    # Returns self.
    def save!(follow_link: true)
      raise(ReadOnlyCSVError) if @path.nil? || !@path.to_s.end_with?('.csv')

      path.unlink if !follow_link && path.symlink?

      FileUtils.mkdir_p(path.dirname)
      File.write(path, table.to_csv)
      self
    end

    # Public: Sets the value of a cell identified by its row and column.
    # Non-existing rows are created automatically.
    #
    # row    - The unique row name.
    # column - The name of the column in which the data shall be put.
    # value  - The value that shall be set.
    #
    # Returns the set cell contents.
    def set(row, column, value)
      set_cell(normalize_key(row), normalize_key(column), value)
    end

    # Public: Retrieves the value of a cell identified by its row and column.
    #
    # row    - The unique row name.
    # column - The name of the column in which the data resides.
    #
    # Returns the cell contents as a number if possible, a string otherwise.
    def get(row, column)
      cell(normalize_key(row), normalize_key(column))
    end

    def row_keys
      table.map { |row| normalize_key(row[0]) }
    end

    def column_keys
      @headers.map(&method(:normalize_key))
    end

    private

    # Internal: Finds the value of a cell, raising an UnknownCSVRowError if no
    # such row exists.
    #
    # Returns the cell content.
    def cell(row_key, column_key)
      assert_header(column_key)

      (table_row = row(row_key)) && table_row[column_key]
    end

    # Internal: Sets the value of a cell, raising an UnknownCSVCellError if no
    # such column exists. Non-existing rows are created automatically.
    #
    # Returns the cell content.
    def set_cell(row_key, column_key, value)
      assert_header(column_key)

      get_or_create_row(row_key)[column_key] = value
    end

    # Internal: Finds the row by the given +key+.
    #
    # Returns a CSV::Row or raises an UnknownCSVRowError if no such row exists
    # in the file.
    def row(key)
      safe_row(key) || fail(UnknownCSVRowError.new(self, key))
    end

    # Internal: Finds the row by the given +key+.
    #
    # Returns a CSV::Row or nil.
    def safe_row(key)
      keyed_table[key]
    end

    # Internal: Precomputes the normalized key of each row for faster lookups.
    #
    # Returns a Hash of CSV::Row.
    def keyed_table
      @keyed_table ||= table.each_with_object({}) do |row, hash|
        hash[normalize_key(row[0])] = row
      end
    end

    # Internal: Finds the row by the given +key+ or creates it if no such
    # row exists in the file.
    #
    # Returns a CSV::Row.
    def get_or_create_row(key)
      safe_row(key) || begin
        row = CSV::Row.new(@headers, [key])
        table << row
        @keyed_table = nil

        safe_row(key)
      end
    end

    # Internal: Converts the given key to a format which removes all special
    # characters.
    #
    # Returns a Symbol.
    def normalize_key(key)
      self.class.normalize_key(key)
    end

    # Internal: Raises unless the named column exists in the file.
    # Never raises if the column is named by index (a number)
    #
    # Returns true or false.
    def assert_header(key)
      unless key.is_a?(Numeric) || @headers.nil? || @headers.include?(key)
        fail UnknownCSVCellError.new(self, key)
      end
    end
  end

  # A special case of CSVDocument where the file contains only two columns;
  # one with a "key" for the row, and one with a value. The name of the
  # headers is not important.
  class CSVDocument::OneDimensional < CSVDocument
    # Public: Retrieves the value of a cell identified by its row.
    #
    # row - The unique row name.
    #
    # Returns the cell contents as a number if possible, a string otherwise.
    def get(row)
      cell(normalize_key(row), 1)
    end
  end

  # A special case of CSVDocument where the file contains multiple index columns;
  # for instance sector, subsector and key
  class CSVDocument::MultiIndex < CSVDocument
    # Internal: Sets the multi-index size
    #
    # Returns a CSVDocument.
    def initialize(table, path = nil, index_size: 3)
      super(table, path = path)

      @index_size = index_size
    end

    # Public: flattens the table into a hash (Symbol, Float)
    # Start_year is cut of from the hash keys as it will serve as the default
    def to_hash
      keyed_table.each_with_object({}) do |(key, row), result|
        row.headers[@index_size..].each do |col|
          year = col == :start_year ? '' : col
          result[normalize_key(row[0...@index_size].reject(&:blank?),year)] = row[col]
        end
      end
    end

    private

    # Internal: Precomputes the normalized key of each row for faster lookups.
    #
    # Returns a Hash of CSV::Row.
    def keyed_table
      @keyed_table ||= table.each_with_object({}) do |row, hash|
        hash[normalize_key(*row[0...@index_size].reject(&:blank?))] = row
      end
    end

    # Internal: Converts the given key(s) to a format which removes all special
    # characters. And joins them in multi-index style
    #
    # Returns a Symbol.
    def normalize_key(*keys)
      keys.map{ |key| self.class.normalize_key(key)}.reject(&:blank?).join('_').to_sym
    end
  end

  # A specialized MultiIndex for emissions data where the value is in a single column
  # rather than spread across multiple year columns.
  #
  # CSV structure: sector, sub_sector, type, ghg, value, unit
  class CSVDocument::EmissionsDocument < CSVDocument::MultiIndex
    # Public: Retrieves an emissions value by its composite key.
    #
    # key - Symbol representing the emission (e.g., :households_energetic_co2)
    #
    # Returns the emission value (Float) or nil if the cell is empty.
    # Raises UnknownCSVRowError if the row doesn't exist.
    def get(key)
      normalized = normalize_key(key)
      row = keyed_table[normalized]

      fail(UnknownCSVRowError.new(self, key)) unless row

      row[:value]
    end

    # Public: Converts the emissions table to a hash.
    # Returns a Hash of emission keys to values.
    def to_hash
      keyed_table.each_with_object({}) do |(key, row), result|
        result[key] = row[:value]
      end
    end
  end
end
