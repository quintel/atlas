module Atlas
  class SparseGraphQuery
    include ActiveDocument

    DIRECTORY = 'sparse_graph_queries'
    VALID_NAME = /^[\w_@-]+\+[\w_]+$/

    attr_accessor :part
    attr_accessor :graph_method

    attribute :query, String

    validate :validate_part
    validates_inclusion_of :graph_method,
      in: GraphValues::VALID_GRAPH_METHODS,
      if: Proc.new{|s| s.graph_part? }

    validates_inclusion_of :graph_method,
      in: Dataset::Derived.attribute_set.map {|a| a.name.to_s },
      if: Proc.new{|s| !s.graph_part? }

    def key
      :"#{part}+#{graph_method}"
    end

    def graph_part?
      Node.exists?(part) || Edge.exists?(part)
    end

    private

    def attributes_from_basename(name)
      if name.nil? || !name.match(VALID_NAME)
        fail InvalidKeyError.new(name)
      end

      part, graph_method = name.split('+')

      {
        part: part,
        graph_method: graph_method
      }
    end

    def validate_part
      return if graph_part? || part == 'area'

      errors.add(:part, "no such node, edge or scope exists: #{part}")
    end
  end
end
