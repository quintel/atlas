# frozen_string_literal: true

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
          comments = blocks { |b| b.is_a?(CommentBlock) }
          comments.any? && comments.first.value || nil
        end

        def properties
          Atlas::Util.expand_dotted_hash(
            blocks_to_hash(blocks { |b| b.type == :static_variable })
          )
        end

        def queries
          blocks_to_hash(blocks { |b| b.type == :dynamic_variable })
        end

        def blocks
          @blocks ||= LineGrouper.new(lines).blocks

          if block_given?
            @blocks.select { |block| yield block }
          else
            @blocks
          end
        end

        # Public: Adds a Line and returns it. Also sets the parent on the line
        # and for simplicity adds the current_line number.
        #
        # Returns the line that was added.
        def add_line(line)
          @lines << line
          line
        end

        private

        def parse_chunk_to_lines(chunk)
          chunk.split("\n").each do |line_content|
            add_line(Line.new(line_content))
          end
        end

        # Internal: Given an array of parsed blocks, converts the properties
        # within the blocks into a single hash.
        #
        # Returns a hash.
        def blocks_to_hash(blocks)
          blocks.each_with_object({}) do |block, hash|
            hash.merge!(block.to_hash)
          end
        end
      end
    end
  end
end
