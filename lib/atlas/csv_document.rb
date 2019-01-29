module Atlas
  class CSVDocument
    attr_reader :path
    attr_reader :table

    # Columns called "year" will be converted to an integer.
    YEAR_NORMALIZER = lambda do |value, info|
      info.header == :year ? value.to_f.to_i : value
    end

    # Public: Reads a CSV file whose contents is a simple list of values with
    # no headers.
    #
    # Returns an Array.
    def self.curve(path)
      CSV.read(
        path.to_s, converters: [YEAR_NORMALIZER, :float]
      ).map(&:first).compact
    end

    # A lambda which converts strings to a consistent format for keys in
    # CSV files.
    # Public: Creates a new CSV document instance which will read data from a
    # CSV file on disk. Documents are read-write.
    #
    # path - Path to the CSV file.
    #
    # Returns a CSVDocument.
    def initialize(path, headers = nil)
      @path = Pathname.new(path)

      if headers
        raise(ExistingCSVHeaderError, path) if @path.file?
        @headers = headers.map { |header| normalize_key(header) }
        @table = CSV::Table.new([CSV::Row.new(@headers, @headers, true)])
      else
        @table = CSV.table(
          @path.to_s,
          converters: value_converters,
          header_converters: [->(header) { normalize_key(header) }],
          # Needed to retrieve the headers in case
          # of an otherwise empty csv file
          return_headers: true
        )

        @headers = table.headers

        # Delete the header row for the internal representation -
        # will be dynamically (re-)created when outputting
        table.delete(0)

        raise(BlankCSVHeaderError, path) if @headers.any?(&:nil?)
      end
    end

    # Public: Saves the CSV document to disk
    def save!
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

    #######
    private
    #######

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
      case key
      when Numeric, nil
        # nils never happen here in Ruby >= 2.3 since nils
        # skip the normalizer.
        key
      else
        key.to_s.downcase.strip
          .gsub(/(?:\s+|-)/, '_')
          .gsub(/[^a-zA-Z0-9_]+/, '')
          .gsub(/_+/, '_')
          .gsub(/_$/, '')
          .to_sym
      end
    end

    # Internal: Procs passed to the CSV::Table describing how to convert values
    # from the CSV to Ruby types.
    #
    # Returns an Array of Procs or Symbols.
    def value_converters
      [YEAR_NORMALIZER, :float]
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
  end # CSVDocument

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
  end # CSVDocument::OneDimensional
end # Atlas
