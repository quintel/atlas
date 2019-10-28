# frozen_string_literal: true

module Atlas
  module Parser
    module TextToHash
      class MultiLineBlock < Block
        FIRST_LINE = /^[-~]\s([a-z_]*)\s=\s*$/.freeze

        def key
          if match = lines.first.to_s.match(FIRST_LINE)
            match.captures.first.to_sym
          else
            raise InvalidMultilineBlockError, lines
          end
        end

        def value
          lines[1..-1].map(&:to_s).map { |l| l[2..-1] }
            .join("\n").strip_heredoc.rstrip
        end
      end
    end
  end
end
