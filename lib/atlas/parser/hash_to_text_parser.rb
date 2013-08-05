module Atlas

  # The HashToTextParser takes care of translating hashes to text
  #
  # Example:
  #
  #   p = Parser.new({comments: "line 1\nline2", unit: "%", query: "SUM(1+2)"})
  #   p.to_text
  #   => "# line1
  #       # line2
  #       - unit = '%'
  #       SUM(1,2)"

  class HashToTextParser

    Encoding.default_external = Encoding::UTF_8
    Encoding.default_internal = Encoding::UTF_8

    ATTR_PREFIX  = "-"
    ATTR_LINE    = /#{ATTR_PREFIX}\s(.+)\s=\s(.+)/
    COMMENT_LINE = /^#(.+)/
    GQUERY_LINE  = /[^\s]+/

    attr_reader :hash

    def initialize(input)
      raise ArgumentError unless input.is_a?(Hash)
      @comments   = input.delete(:comments)
      @queries    = input.delete(:queries)
      @attributes = input
    end

    def to_text
      content = [
        comment_block,
        attributes_block,
        queries_block
      ].compact.join("\n\n").rstrip

      content
    end

    #######
    private
    #######

    def comment_block
      return nil unless @comments

      @comments.lines.to_a.map do |line|
        stripped = line.rstrip
        line.strip.length > 0 ? "# #{ stripped }" : '#'
      end.join("\n")
    end

    def queries_block
      return unless @queries

      @queries.map do |key, value|
        "~ #{ format_attribute(key, value) }"
      end
    end

    # Internal: Lines containing the attributes for the document, whichi will
    # be written to the file on disk.
    #
    # Returns a string.
    def attributes_block
      if (lines = lines_from_hash(@attributes)).any?
        lines.join("\n")
      end
    end

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

        "- #{ format_attribute(key, value) }"
      end
    end

    def format_attribute(key, value)
      if value.to_s.include?("\n")
        "#{ key } =\n    #{ value.split("\n").join("\n    ") }"
      else
        "#{ key } = #{ value }"
      end
    end

  end # HashToTextParser
end # Atlas
