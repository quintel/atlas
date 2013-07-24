module Atlas
  module Parser
    module TextToHash
      class Line

        attr_accessor :parent, :number
        attr_reader   :string

        def initialize(string)
          @string = string
        end

        def to_s
          string
        end

        def type
          Atlas::Parser::Identifier.type(string)
        end

      end
    end
  end
end
