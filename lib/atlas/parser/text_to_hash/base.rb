module Atlas
  module Parser
    module TextToHash
      class Base

        def initialize(content = nil)
          @lines        = {}
          @current_line = 0

          parse_chunk_to_lines(content) if content
        end

        # Public: Returns a Hash containing Line objects with the correcponding
        # line number.
        # example
        #   { 1 => <Atlas::Parser::TextToHash::Line [...]>,
        #     2 => <Atlas::Parser::TextToHash::Line [...]> }
        def lines
          @lines
        end

        def blocks
          Atlas::Parser::LineGrouper.groups(lines)
        end

        # Public: Adds a Line and returns it. Also sets the parent on the line
        # and for simplicity adds the current_line number.
        def add_line(line)
          line.parent = self
          line.number = @current_line += 1
          @lines[line.number] = line
        end

        #######
        private
        #######

        def parse_chunk_to_lines(chunk)
           chunk.split('\n').each do |line_content|
             add_line(Line.new(line_content))
           end
        end

      end
    end
  end
end
