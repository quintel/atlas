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

    attr_reader :input

    def initialize(input)
      fail ArgumentError unless input.is_a?(Hash)
      @input = input
    end

    def to_csv
      content = Atlas::HashToTextParser.new(input).to_attributes
      content.gsub!(/^-\s/,"")
      content.gsub!(/\s=\s/,",")
    end

  end # HashToCSVParser
end # Atlas
