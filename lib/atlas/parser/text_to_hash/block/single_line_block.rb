module Atlas
  module Parser
    module TextToHash

      class SingleLineBlock < Block

        LINE = /^-\s([a-z_]*)\s=\s(\w*)$/

        def key
          lines.first.to_s.match(LINE).captures.first.to_sym
        end

        def value
          lines.first.to_s.match(LINE).captures.last
        end
      end

    end
  end
end
