module Tome
  class CSVDocument
    attr_reader :path

    # Unfortunately, the CSV library provides us with no means to set the
    # header converter at runtime; it has to be added globally.
    CSV::HeaderConverters[:tome] = ->(key) do
      case key
        when nil
          raise(InvalidKeyError.new(key))
        when Integer
          key
        else
          key.to_s.downcase.strip.
            gsub(/\s+/, '_').
            gsub(/[^a-zA-Z0-9_]+/, '').
            gsub(/_+/, '_').
            gsub(/_$/, '').
            to_sym
      end
    end

    # Public: Creates a new CSV document instance which will read data from a
    # CSV file on disk. Document are read-only.
    #
    # path - Path to the CSV file.
    #
    # Returns a CSVDocument.
    def initialize(path, csv_opts = { header_converters: [:tome] })
      @path  = Pathname.new(path)
      @table = CSV.table(@path.to_s, csv_opts)
    rescue InvalidKeyError
      raise BlankCSVHeaderError.new(path)
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

    #######
    private
    #######

    # Internal: Finds the value of a cell, raising an UnknownCSVRowError if no
    # such row exists, or an UnknownCSVCellError if the row exists, but there
    # is no such column.
    #
    # Returns the cell content.
    def cell(row_key, column_key)
      (data = row(row_key)) && data[column_key] ||
        raise(UnknownCSVCellError.new(self, column_key))
    end

    # Internal: Finds the row by the given +key+.
    #
    # Returns a CSV::Row or raises an UnknownCSVRowError if no such row exists
    # in the file.
    def row(key)
      @table.find { |row| normalize_key(row[0]) == key } ||
        raise(UnknownCSVRowError.new(self, key))
    end

    # Internal: Converts the given key to a format which removes all special
    # characters.
    #
    # Returns a Symbol.
    def normalize_key(key)
      CSV::HeaderConverters[:tome].call(key)
    end
  end # CSVDocument

  # A special cast of CSVDocument where the file contains only two columns;
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
end # Tome
