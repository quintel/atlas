# frozen_string_literal: true

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

    ATTR_PREFIX  = '-'
    ATTR_LINE    = /#{ATTR_PREFIX}\s(.+)\s=\s(.+)/.freeze
    COMMENT_LINE = /^#(.+)/.freeze
    GQUERY_LINE  = /[^\s]+/.freeze

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

    private

    def comment_block
      return nil unless @comments

      @comments.lines.to_a.map do |line|
        stripped = line.rstrip
        !line.strip.empty? ? "# #{stripped}" : '#'
      end.join("\n")
    end

    def queries_block
      return unless @queries

      @queries.map do |key, value|
        "~ #{format_attribute(key, value)}"
      end
    end

    # Internal: Lines containing the attributes for the document, whichi will
    # be written to the file on disk.
    #
    # Returns a string.
    def attributes_block
      reducers = [
        method(:cast_for_serialization),
        Atlas::Util.method(:flatten_dotted_hash),
        method(:lines_from_hash)
      ]

      lines =
        reducers.reduce(@attributes) do |attrs, reducer|
          reducer.call(attrs)
        end

      lines.join("\n") if lines.any?
    end

    # Internal: Given a hash of attributes, returns an array of lines
    # representing each key/value pair in the hash. Recurses into hashes.
    #
    # hash   - The hash of attributes to be formatted.
    # prefix - An optional prefix to be prepended to each key name. Used when
    #          formatting lines within nested hashes.
    #
    # Returns an array of strings.
    def lines_from_hash(hash, _prefix = nil)
      hash.map do |key, value|
        if value.is_a?(Array) || value.is_a?(Set)
          value = "[#{value.to_a.join(', ')}]"
        end

        "- #{format_attribute(key, value)}"
      end
    end

    # Internal: Converts embedded and value objects into hashes, which are
    # subsequently saved using the "dotted-hash" format.
    #
    # hash - The hash which may contain Virtus values.
    #
    # Returns a new hash.
    def cast_for_serialization(hash)
      hash.each_with_object({}) do |(key, value), cast|
        cast[key] =
          case value
          when Virtus::Model::Core
            Hash[
              Atlas::Util
              .serializable_attributes(value.attributes)
              .sort_by(&:first)
            ]
          when Hash
            Hash[value.sort_by(&:first)]
          else
            value
          end
      end
    end

    def format_attribute(key, value)
      if value.to_s.include?("\n")
        "#{key} =\n    #{value.split("\n").join("\n    ")}"
      else
        "#{key} = #{value}"
      end
    end
  end
end
