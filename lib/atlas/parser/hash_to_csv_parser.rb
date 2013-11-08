module Atlas

  # The HashToCSVParser takes care of translating hashes to csv
  #
  # Example:
  #
  #   p = HashToCSVParser.new({unit: "%", bar: "blah", hash: {one: two}})
  #   p.to_csv
  #   => "unit, %\n
  #       bar, blah\n
  #       hash.one, two\n"

  class HashToCSVParser

    def initialize(input)
      fail ArgumentError unless input.is_a?(Hash)
      @input = input
    end

    def to_csv
      lines_from_hash(@input).join("\n")
    end

    #######
    private
    #######

    # Internal: Given a hash of attributes, returns an array of lines
    # representing each key/value pair in the hash. Recurses into hashes.
    #
    # hash   - The hash of attributes to be formatted.
    # prefix - An optional prefix to be prepended to each key name. Used when
    #          formatting lines within nested hashes.
    #
    # Returns an array of strings.
    def lines_from_hash(hash, prefix = nil)
      Atlas::Util.flatten_dotted_hash(hash).map do |key, value|
        if value.is_a?(Array) || value.is_a?(Set)
          value = "[#{ value.to_a.join(', ') }]"
        end

        "#{ key },#{ value }"
      end
    end

  end # HashToCSVParser
end # Atlas
