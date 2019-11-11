module Atlas
  module Util
    module_function

    # Public: Given a hash which itself contains hashes, flattens the
    # structure so that the values in each nested hash are moved -- with
    # namespace-style dots -- to the top-level hash.
    #
    # hash - The hash to be flattened.
    # ns   - The current namespace in the hash traversal; used internally when
    #        recursing.
    #
    # For example:
    #
    #   flatten_dotted_hash({ one: 1, two: { three: 4 }})
    #   # => { :one => 1, "two.three" => 4 }
    #
    # Returns a new hash; does not alter the argument.
    def flatten_dotted_hash(hash, ns = nil)
      dotted = {}

      hash.each do |key, value|
        full_key = ns ? "#{ ns }.#{ key }" : key

        case value
        when Hash
          dotted.merge!(flatten_dotted_hash(value, full_key))
        when Array, Set
          if value.any? { |element| element.is_a?(Hash) }
            fail IllegalNestedHashError.new(value)
          end

          dotted[full_key] = value
        else
          dotted[full_key] = value
        end
      end

      dotted
    end

    # Public: Given a hash which has been flattened by +flatten_dotted_hash+,
    # expands the dotted keys back out to the original hashes. Hash keys are
    # converted to symbols.
    #
    # hash - The hash to expand.
    #
    # Returns a new hash; does not alter the argument.
    def expand_dotted_hash(hash)
      expanded = {}

      hash.each do |key, value|
        if key.to_s.include?('.')
          # Nested hash value.
          split = key.to_s.split('.')

          head  = split.first.to_sym
          rest  = split[1..-1].map(&:to_sym)

          hval  = expanded[head] ||= Hash.new

          rest.to_enum.with_index.reduce(hval) do |parent, (segment, index)|
            if rest[index + 1].nil?
              # This is the final segment; set the value.
              parent[segment] = value
            else
              # We're in a middle segment (i.e., not the first not the last:
              # given "one.two.three.four" -> "two" and "three").
              parent[segment] ||= Hash.new
            end
          end
        else
          expanded[key.to_sym] = value
        end
      end

      expanded
    end

    # A hash of attributes and values from a document which can be persisted.
    #
    # Returns a Hash.
    def serializable_attributes(attributes)
      attributes.reject { |_, value| value != false && value.blank? }
    end

    # Public: Rounds the given number to the nearest integer, but only
    # if it is already very close (1e-6) to this integer (which is not 0)
    def round_computation_errors(float)
      int = float.round
      if int != 0 && int == float.round(6)
        int.to_f
      else
        float
      end
    end

    # Public: Loads the curve at the given `path` using Merit.
    #
    # Raises a Merit::MissingLoadProfileError if the file does not exist, or
    # Atlas::MeritRequired if the Merit library has not been loaded.
    #
    # Returns a Merit::Curve.
    def load_curve(path)
      Merit::LoadProfile.load(path)
    rescue NameError => e
      raise(e.message.match(/Merit$/) ? MeritRequired : ex)
    end
  end # Util
end # Atlas
