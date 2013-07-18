module Atlas
  module Parser
    module TextToHash
      class Line

        attr_accessor :parent, :number
        attr_reader   :string

        def initialize(string)
          @string = string
        end

        # Returns a Line that is the predecessor
        # or nil when there ain't none
        def pred
          parent.lines[number.pred]
        end

        # Returns a Line that is the successor
        # or nil when there ain't none
        def succ
          parent.lines[number.succ]
        end

        def type
          Atlas::Parser::Identifier.type(string)
        end

      end
    end
  end
end
