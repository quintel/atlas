module Atlas
  class CSVDocument
    attr_reader :path

    # A lambda which converts strings to a consistent format for keys in
    # CSV files.
    KEY_NORMALIZER = lambda do |key|
      case key
      when nil
        raise(InvalidKeyError.new(key))
      when Integer
        key
      else
        key.to_s.downcase.strip
          .gsub(/\s+/, '_')
          .gsub(/[^a-zA-Z0-9_]+/, '')
          .gsub(/_+/, '_')
          .gsub(/_$/, '')
          .to_sym
      end
    end

    # Public: Creates a new CSV document instance which will read data from a
    # CSV file on disk. Document are read-only.
    #
    # path - Path to the CSV file.
    #
    # Returns a CSVDocument.
    def initialize(path, normalizer = KEY_NORMALIZER)
      @path  = Pathname.new(path)
      @table = CSV.table(@path.to_s, header_converters: [normalizer])
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
    # such row exists.
    #
    # Returns the cell content.
    def cell(row_key, column_key)
      (data = row(row_key)) && data[column_key]
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
      KEY_NORMALIZER.call(key)
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

  # A CSVDocument which reads CSV files which are output by the Exporter. Each
  # left-hand column is a node, edge, or slot key whose value needs to be
  # preserved without removing special characters.
  class CSVDocument::Production < CSVDocument
    def initialize(path)
      super(path, ->(value) { value.to_sym })
    end
  end # CSVDocument::Production
end # Atlas
