module Atlas
  module Parser
    module TextToHash

      # A CommentBlock is really something similar to what your reading now.
      # Every line is prepended with a hash (#) and there's always a space
      # between the hash (#) and the first character.
      class CommentBlock < Block

        def key
          :comment
        end

        def value
          lines.map(&:to_s).map { |l| l[2..-1] }.join("\n")
        end
      end

    end
  end
end
