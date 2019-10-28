# frozen_string_literal: true

module Atlas
  module Parser
    module TextToHash
      class Line
        def initialize(string)
          @string = string
        end

        def to_s
          @string
        end

        def type
          Atlas::Parser::Identifier.type(@string)
        end
      end
    end
  end
end
