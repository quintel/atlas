module Atlas
  module Parser
    module TextToHash
      class LineGrouper

        attr_reader :lines, :blocks

        def initialize(lines)
          @lines  = lines
          @blocks = []
          parse_to_blocks!
        end

        private

        # Check if a line starts a multi-line array (has '= [' but no closing ']')
        def multi_line_array_start?(line)
          line_str = line.to_s
          # Match lines like "- groups = [" or "~ query = ["
          if line_str.match?(/^[-~]\s[a-z0-9_.]*\s+=\s*\[/)
            # Check if there's NO closing bracket on the same line
            value_part = line_str.split('=', 2).last.strip
            value_part.start_with?('[') && !value_part.end_with?(']')
          else
            false
          end
        end

        def parse_to_blocks!

          in_comment_block = nil

          lines.each_with_index do |line, index|

            if line.type == :empty_line
              if @blocks.last.is_a?(MultiLineBlock)
                @blocks.last.lines << line
              end

              next
            end

            if line.type == :inner_block
              @blocks.last.lines << line
              next
            end

            if line.type == :comment
              if in_comment_block
                @blocks.last.lines << line
                next
              end
              in_comment_block = true
            end

            if lines[index + 1] && lines[index + 1].type == :inner_block
              # Multi-line arrays use SimpleAttributeBlock; other multi-line content uses MultiLineBlock
              if multi_line_array_start?(line)
                @blocks << SimpleAttributeBlock.new([line])
              else
                @blocks << MultiLineBlock.new([line])
              end
            elsif line.type == :comment
              @blocks << CommentBlock.new([line])
            else
              @blocks << SimpleAttributeBlock.new([line])
            end
          end

        end

      end
    end
  end
end
