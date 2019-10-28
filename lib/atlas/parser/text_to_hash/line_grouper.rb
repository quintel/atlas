# frozen_string_literal: true

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

        def parse_to_blocks!
          in_comment_block = nil

          lines.each_with_index do |line, index|
            if line.type == :empty_line
              @blocks.last.lines << line if @blocks.last.is_a?(MultiLineBlock)

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

            @blocks.push(
              if lines[index + 1] && lines[index + 1].type == :inner_block
                MultiLineBlock.new([line])
              elsif line.type == :comment
                CommentBlock.new([line])
              else
                SingleLineBlock.new([line])
              end
            )
          end
        end
      end
    end
  end
end
