module Atlas
  module Parser
    module TextToHash

      class SingleLineBlock < Block

        # TODO: Integrate with Regex from Line?
        LINE = /^[-~]\s([a-z0-9_.]*)\s+=(?:\s*(.*))$/

        def valid?
          line.to_s.match(LINE)
        end

        # There is only one
        def line
          lines.first
        end

        def key
          validate!
          lines.first.to_s.match(LINE).captures.first.to_sym
        end

        def value
          validate!
          cast_scalar(lines.first.to_s.match(LINE).captures.last)
        end

        #######
        private
        #######

        def validate!
          raise CannotParseError.new(line, self) unless valid?
        end

        def cast_scalar(text)
          return text if query?

          case text
          when /\A[-+]?[0-9]*\.[0-9]+([eE][-+]?[0-9]+)?\z/
            text.to_f
          when /\A[-+]?\d+\z/
            text.to_i
          else
            text
          end
        end

      end

    end
  end
end
