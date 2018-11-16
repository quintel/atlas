# frozen_string_literal: true

module Atlas
  class Dataset
    # Describes the cost of insulation in households and buildings.
    #
    # The underlying file may take one of two forms:
    #
    # 1) A matrix of insulation levels as both row and column keys, with each
    #    cell describing the cost of moving from one level (specified in the
    #    first column) to another.
    #
    #      present, 0,  1,  2
    #      0,       0, 10, 20
    #      1,      -1,  0,  5
    #      2,      -5, -3,  0
    #
    #    Moving from level 1 to level 2 has a cost of 5. Moving from level 0
    #    to level 1 has a cost of 10, etc.
    #
    # 2) A CSV where the first column contains the key of a building type, and
    #    each subsequent column describes the insulation level. Such as CSV
    #    describes the cost of building a new household or building with the
    #    given insulation level.
    #
    #      type,0,1,2,3
    #      apartment,1,2,3,4
    #      building,10,20,30,40
    #
    #    Constructing a new apartment whose insulation level is 1 will cost 2,
    #    while a new building with insulation level 3 will cost 40.
    #
    # When looking up values with InsulationCostCSV#get, insulation levels may
    # be specified as an Integer 1, Symbol :"1", String "1", or Float 1.0.
    # Float keys are truncated to Integers.
    class InsulationCostCSV < CSVDocument
      # Values in the "present" column are converted to Symbols.
      LEVEL_VALUE_NORMALIZER = lambda do |value, info|
        info.header == :present ? Integer(value).to_s.to_sym : value
      end

      private

      def value_converters
        [LEVEL_VALUE_NORMALIZER, :float]
      end

      # Internal: Converts a CSV header key to a standard format.
      def normalize_key(key)
        return Integer(key).to_s.to_sym if key.is_a?(Numeric)

        int_key = CSV::Converters[:integer].call(key)
        int_key.is_a?(Integer) ? int_key.to_s.to_sym : key.to_sym
      end
    end
  end
end
