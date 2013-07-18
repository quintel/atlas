module Atlas
  module Parser
    class Identifier

      ATTR_PREFIX    = "-"
      QUERY_PREFIX   = "~"
      COMMENT_PREFIX = "#"

      COMMENT_LINE   = /^#{ COMMENT_PREFIX }(.*)/
      ATTR_LINE      = /^#{ ATTR_PREFIX }\s(.+)\s=\s?(.*)/
      QUERY_LINE     = /^#{ QUERY_PREFIX }\s(.+)\s=/
      INNER_BLOCK    = /^\s\s(.+)/

      def self.type(string)
        case string
        when COMMENT_LINE
          :comment
        when ATTR_LINE
          :static_variable
        when QUERY_LINE
          :dynamic_variable
        when INNER_BLOCK
          :inner_block
        else
          raise CannotIdentifyError.new(string)
        end
      end

    end
  end
end
