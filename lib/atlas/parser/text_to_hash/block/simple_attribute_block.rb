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

          first_value = lines.first.to_s.match(LINE)&.captures&.last&.strip
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

        def parse_single_line_value
          value = lines.first.to_s.match(LINE).captures.last.strip

          if value[0] == ARR_START && value[-1] == ARR_END
            # [arrays, of, values]
            value[1..-2].split(',').map { |el| cast_scalar(el.strip) }
          else
            cast_scalar(value)
          end
        end

        def parse_multi_line_array
          # Collect all content from all lines
          all_content = []

          # First line: extract everything after '= ['
          first_value = lines.first.to_s.match(LINE).captures.last.strip
          all_content << first_value[1..-1] # Remove opening '['

          # Subsequent lines: collect until we find ']'
          lines[1..-1].each do |line|
            line_str = line.to_s.strip
            if line_str.end_with?(ARR_END)
              # Remove closing ']' and add final content
              all_content << line_str[0..-2]
              break
            else
              all_content << line_str
            end
          end

          # Join all content, split by commas, and parse each element
          all_content.join(' ').split(',').map { |el| cast_scalar(el.strip) }
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
