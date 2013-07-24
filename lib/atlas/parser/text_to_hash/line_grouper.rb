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

          lines.each do |line|

            next if line.type == :empty_line

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

            case line.type
            when :comment
              @blocks << CommentBlock.new([line])
            when :dynamic_variable
              @blocks << MultiLineBlock.new([line])
            else
              @blocks << SingleLineBlock.new([line])
            end
          end

        end

      end
    end
  end
end
