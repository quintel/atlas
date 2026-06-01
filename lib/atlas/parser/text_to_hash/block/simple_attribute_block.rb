module Atlas
  module Parser
    module TextToHash

      class SimpleAttributeBlock < Block

        # TODO: Integrate with Regex from Line?
        LINE = /^[-~]\s([a-z0-9_.]*)\s+=(?:\s*(.*))$/

        ARR_START = '['.freeze
        ARR_END   = ']'.freeze

        def valid?
          line.to_s.match(LINE)
        end

        # There is only one line for simple attributes,
        # but multi-line arrays can have multiple lines
        def line
          lines.first
        end

        # Check if this is a multi-line array
        def multi_line_array?
          return false if lines.size == 1

          first_value = first_raw_value
          first_value && first_value.start_with?(ARR_START) && !first_value.end_with?(ARR_END)
        end

        def key
          validate!
          lines.first.to_s.match(LINE).captures.first.to_sym
        end

        def value
          validate!

          if multi_line_array?
            parse_multi_line_array
          else
            parse_single_line_value
          end
        end

        private

        def first_raw_value
          lines.first.to_s.match(LINE)&.captures&.last&.strip
        end

        def parse_single_line_value
          value = first_raw_value

          if value[0] == ARR_START && value[-1] == ARR_END
            parse_array_elements(value[1..-2])
          else
            cast_scalar(value)
          end
        end

        def parse_multi_line_array
          content = collect_array_content
          parse_array_elements(content)
        end

        def collect_array_content
          content = [first_raw_value[1..-1]]

          lines[1..-1].each do |line|
            line_str = line.to_s.strip
            content << (line_str.end_with?(ARR_END) ? line_str[0..-2] : line_str)
            break if line_str.end_with?(ARR_END)
          end

          content.join(' ')
        end

        def parse_array_elements(content)
          content.split(',').map { |el| cast_scalar(el.strip) }
        end

        def validate!
          fail CannotParseError.new(line, self) unless valid?
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
