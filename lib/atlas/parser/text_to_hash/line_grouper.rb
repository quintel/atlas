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

        #######
        private
        #######

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
              @blocks << MultiLineBlock.new([line])
            elsif line.type == :comment
              @blocks << CommentBlock.new([line])
            else
              @blocks << SingleLineBlock.new([line])
            end
          end

        end

      end
    end
  end
end
