# frozen_string_literal: true

module Atlas
  # Relates canonical ETM sector labels to external classification schemes
  # (IPCC CRT codes, klimaattafels, national emissions sectors, ...).
  #
  # The mapping is a single CSV in ETSource `config/sector_mapping.csv`. Each
  # row is identified by the composite (`sector_label`, `use`) pair; every other
  # column is a *classification scheme* whose cell points that pair at an
  # external value. `sector_label` and `use` are themselves queryable schemes.
  #
  # A node "belongs to" a scheme value when its own (`sector_label`, `use`) pair
  # matches a mapping row whose cell in that scheme column resolves to the value.
  # Matching the pair — not the label alone — is what keeps energetic and non-energetic
  # emissions from being conflated.
  #
  # `-` and blank cells are treated as "no value": unqueryable, and looking up
  # `'-'` behaves like any unknown value.

  class SectorMapping
    LABEL_COLUMN = :sector_label
    USE_COLUMN   = :use
    BLANK_CELL = '-'

    # Public: One mapping row, exposing the raw display value of each scheme
    # cell (never a normalized slug) alongside the row's (label, use) pair.
    #
    # `cells` is a Hash of {scheme => String}; blank/"-" cells are omitted (so
    # `cells[scheme]` is nil), matching {.normalize}'s notion of "no value".
    RawRow = Struct.new(:pair, :cells)

    class << self
      # Public: The single normalizer, shared by import and query. Reuses the CSV document
      # key-normalizer.
      #
      # Returns a Symbol, or nil for blank / "-" cells.
      def normalize(value)
        string = value.to_s.strip
        return nil if string.empty? || string == BLANK_CELL

        CSVDocument.normalize_key(string)
      end

      # Public: The mapping loaded from the ETSource config directory, memoized
      # for the current Atlas data dir.
      def load
        path = default_path

        if @loaded_from != path
          @loaded   = from_path(path)
          @loaded_from = path
        end

        @loaded
      end

      # Public: Path to the mapping CSV within the active ETSource data dir.
      def default_path
        Atlas.data_dir.join('config', 'sector_mapping.csv')
      end

      # Public: Reads a mapping from a CSV file on disk.
      def from_path(path)
        new(read_table(File.read(path)), path)
      end

      # Public: Reads a mapping from a CSV string (used in tests).
      def from_string(string, path = nil)
        new(read_table(string), path)
      end

      private

      # Internal: Parses the CSV with normalized Symbol headers, but leaves cell
      # values as raw strings so numeric codes such as "2" or "1990" survive
      # into {.normalize} unchanged.
      def read_table(string)
        CSV.parse(
          string,
          headers: true,
          header_converters: [->(header) { CSVDocument.normalize_key(header) }]
        )
      end
    end

    attr_reader :path, :scheme_names

    # Internal: Use {.load}, {.from_path} or {.from_string}.
    def initialize(table, path = nil)
      @path         = path && Pathname(path)
      @scheme_names = table.headers.compact
      build_indices(table)
    end

    # Public: The (sector_label, use) pairs whose `scheme` cell resolves to
    # +value+.
    #
    # Returns a Set of [label, use] pairs (empty for a blank/"-" value).
    def lookup(scheme, value)
      scheme_key = CSVDocument.normalize_key(scheme.to_s)
      assert_scheme!(scheme_key)

      value_key = self.class.normalize(value)
      return Set.new if value_key.nil?

      @index[scheme_key][value_key] || Set.new
    end

    # Public: Whether `scheme` names a column in the mapping.
    def scheme?(scheme)
      @scheme_names.include?(CSVDocument.normalize_key(scheme.to_s))
    end

    # Public: Every (sector_label, use) pair in the mapping. Used by the
    # ETSource validation.
    def pairs
      @pairs
    end

    # Public: Each mapping row as a Hash of {scheme => normalized value}, in file
    # order. Blank / "-" cells are nil.
    def rows
      @rows
    end

    # Public: Each mapping row in file order, as a {RawRow}: the (label, use)
    # pair plus the raw display value of every scheme cell (never a normalized
    # slug). Retained alongside {#rows} so display rendering and lookup
    # normalization read from the same parse and can never disagree.
    def raw_rows
      @raw_rows
    end

    # Public: A plain, serializable copy of the inverted index, shaped
    # {scheme => {value => [[label, use], ...]}}. Consumed by ETEngine.
    def to_h
      @index.each_with_object({}) do |(scheme, values), schemes|
        schemes[scheme] = values.transform_values(&:to_a)
      end
    end

    # Public: The shared normalizer, exposed so callers do not reimplement it.
    def normalize(value)
      self.class.normalize(value)
    end

    private

    def build_indices(table)
      @index    = @scheme_names.each_with_object({}) { |scheme, hash| hash[scheme] = {} }
      @pairs    = Set.new
      @rows     = []
      @raw_rows = []

      # Per-scheme record of {normalized => original} to detect slug collisions.
      seen_values = @scheme_names.each_with_object({}) { |scheme, hash| hash[scheme] = {} }

      table.each do |row|
        pair = row_pair(row)
        raise DuplicateSectorMappingRowError.new(*pair) unless @pairs.add?(pair)

        normalized = {}
        raw = {}
        @scheme_names.each do |scheme|
          normalized[scheme] = self.class.normalize(row[scheme])
          raw[scheme] = raw_cell(row[scheme])
          index_cell(scheme, row[scheme], pair, seen_values[scheme])
        end
        @rows << normalized
        @raw_rows << RawRow.new(pair, raw)
      end
    end

    # Internal: The raw display value of a cell, or nil for a blank / "-" cell.
    # Shares blank-detection with {.normalize} but skips slugification.
    def raw_cell(value)
      string = value.to_s.strip
      string.empty? || string == BLANK_CELL ? nil : string
    end

    def row_pair(row)
      [self.class.normalize(row[LABEL_COLUMN]), self.class.normalize(row[USE_COLUMN])]
    end

    def index_cell(scheme, raw, pair, seen)
      value_key = self.class.normalize(raw)
      return if value_key.nil?

      original = raw.to_s.strip
      if seen.key?(value_key) && seen[value_key] != original
        raise SectorMappingSlugCollisionError.new(scheme, value_key, seen[value_key], original)
      end
      seen[value_key] = original

      (@index[scheme][value_key] ||= Set.new) << pair
    end

    def assert_scheme!(scheme_key)
      return if @scheme_names.include?(scheme_key)

      raise KeyError,
        "Unknown sector mapping scheme #{scheme_key.inspect}. " \
        "Valid schemes: #{@scheme_names.map(&:inspect).join(', ')}."
    end
  end
end
