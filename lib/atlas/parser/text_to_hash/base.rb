module Atlas
  module Parser
    module TextToHash
      class Base

        attr_reader :lines

        def initialize(content = nil)
          @lines        = []
          @current_line = 0

          parse_chunk_to_lines(content) if content
        end

        def to_hash
          { comments: comments, queries: queries }.merge(properties)
        end

        def comments
          unless blocks(CommentBlock).empty?
            blocks(CommentBlock).first.value
          end
        end

        def properties
          blocks(SingleLineBlock).inject({}) do |sum, block|
            sum.merge(block.to_hash)
          end
        end

        def queries
          blocks(MultiLineBlock).inject({}) do |sum, block|
            sum.merge(block.to_hash)
          end
        end

        def blocks(klass = Block)
          LineGrouper.new(lines).blocks.select { |b| b.is_a?(klass) }
        end

        # Public: Adds a Line and returns it. Also sets the parent on the line
        # and for simplicity adds the current_line number.
        #
        # Returns the line that was added.
        def add_line(line)
          @lines << line
          line
        end

        #######
        private
        #######

        def parse_chunk_to_lines(chunk)
          chunk.split("\n").each do |line_content|
            add_line(Line.new(line_content))
          end
        end

      end
    end
  end
end
