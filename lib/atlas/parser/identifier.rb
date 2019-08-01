module Atlas
  module Parser
    class Identifier

      ATTR_PREFIX    = '-'
      QUERY_PREFIX   = '~'
      COMMENT_PREFIX = '#'

      COMMENT_LINE   = /^#{ COMMENT_PREFIX }(.*)/
      ATTR_LINE      = /^#{ ATTR_PREFIX }\s(.+)\s=(?:\s*(.*))/
      QUERY_LINE     = /^#{ QUERY_PREFIX }\s(.+)\s=/
      INNER_BLOCK    = /^\s\s(.+)/

      def self.type(string)
        # Branches are ordered depending on how often we expect to encounter
        # each line type in real documents.
        if match_prefixed_line?(string, ATTR_PREFIX, ATTR_LINE)
          return :static_variable
        elsif match_prefixed_line?(string, QUERY_PREFIX, QUERY_LINE)
          return :dynamic_variable
        elsif string.match?(INNER_BLOCK)
          return :inner_block
        elsif match_prefixed_line?(string, COMMENT_PREFIX, COMMENT_LINE)
          return :comment
        elsif string.empty?
          return :empty_line
        end

        raise CannotIdentifyError, string
      end

      # Internal: Matches a line against a prefix and regex.
      #
      # A prefix is used to match the line before a regex since it provides for
      # a faster exit for lines which would not match the regex.
      #
      # Returns true or false.
      def self.match_prefixed_line?(line, prefix, regex)
        line[0] == prefix && line.match?(regex)
      end
    end
  end
end
