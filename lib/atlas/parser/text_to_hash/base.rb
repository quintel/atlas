module Atlas
  module Parser
    module TextToHash
      class Base

        def initialize(content = nil)
          @lines        = []
          @current_line = 0

          parse_chunk_to_lines(content) if content
        end

        def to_hash
          blocks.inject({}) do |sum, block|
            sum.merge(block.to_hash)
          end
        end

        # Public: Returns an Array containing Line objects
        # example
        #   [ <Atlas::Parser::TextToHash::Line [...]>,
        #     <Atlas::Parser::TextToHash::Line [...]> ]
        def lines
          @lines
        end

        def blocks
          LineGrouper.new(lines).blocks
        end

        # Public: Adds a Line and returns it. Also sets the parent on the line
        # and for simplicity adds the current_line number.
        #
        # Returns the line that was added
        def add_line(line)
          line.parent = self
          line.number = @current_line += 1
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
