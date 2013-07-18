module Atlas
  module Parser
    module TextToHash
      # A Block is a container element for lines with the same type
      # e.g.: 
      class Block

        attr_accessor :lines

        def initialize(lines = nil)
          @lines = []
          @lines = lines if lines
          self
        end

        def type
          lines.first.type
        end

      end
    end
  end
end

