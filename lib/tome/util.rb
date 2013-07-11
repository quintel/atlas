module Tome
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
      dotted = Hash.new

      hash.each do |key, value|
        full_key = ns ? "#{ ns }.#{ key }" : key

        case value
        when Hash
          dotted.merge!(flatten_dotted_hash(value, full_key))
        when Array, Set
          if value.any? { |value| value.is_a?(Hash) }
            raise IllegalNestedHashError.new(value)
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
      expanded = Hash.new

      hash.each do |key, value|
        if key.include?('.')
          # Nested hash value.
          split = key.split('.')

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

  end # Util
end # Tome