# frozen_string_literal: true

module Atlas
  module Parser
    module TextToHash
      class SingleLineBlock < Block
        # TODO: Integrate with Regex from Line?
        LINE = /^[-~]\s([a-z0-9_.]*)\s+=(?:\s*(.*))$/.freeze

        ARR_START = '['
        ARR_END   = ']'

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

          value = lines.first.to_s.match(LINE).captures.last.strip

          if value[0] == ARR_START && value[-1] == ARR_END
            # [arrays, of, values]
            value[1..-2].split(',').map { |el| cast_scalar(el.strip) }
          else
            cast_scalar(value)
          end
        end

        private

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
