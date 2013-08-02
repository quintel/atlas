module Atlas
  module Parser
    module TextToHash

      class MultiLineBlock < Block

        FIRST_LINE = /^[-~]\s([a-z_]*)\s=$/

        def key
          lines.first.to_s.match(FIRST_LINE).captures.first.to_sym
        end

        def value
          lines[1..-1].map(&:to_s).map { |l| l[2..-1] }.
            join("\n").strip_heredoc.rstrip
        end

      end

    end
  end
end
