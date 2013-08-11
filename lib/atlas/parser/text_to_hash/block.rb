module Atlas
  module Parser
    module TextToHash
      # A Block is a container element for lines with the same type
      # for example a comment block, or a dynamic variable block.
      class Block

        attr_accessor :lines

        def initialize(lines = nil)
          @lines = lines || []
        end

        def type
          lines.first.type
        end

        def to_hash
          { key => value }
        end

        def query?
          lines.first.to_s[0] == '~'
        end

      end
    end
  end
end

