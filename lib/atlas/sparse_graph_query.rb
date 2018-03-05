module Atlas
  class SparseGraphQuery
    include ActiveDocument

    DIRECTORY = 'sparse_graph_queries'
    VALID_NAME = /^[\w_@-]+\+[\w_]+$/

    attr_accessor :graph_part
    attr_accessor :graph_method

    attribute :query, String

    validate :validate_graph_part
    validates_inclusion_of :graph_method, in: GraphValues::VALID_GRAPH_METHODS

    def key
      :"#{graph_part}+#{graph_method}"
    end

    private

    def attributes_from_basename(name)
      if name.nil? || !name.match(VALID_NAME)
        fail InvalidKeyError.new(name)
      end

      graph_part, graph_method = name.split('+')

      {
        graph_part: graph_part,
        graph_method: graph_method
      }
    end

    def validate_graph_part
      return if Node.exists?(graph_part) || Edge.exists?(graph_part)

      errors.add(:graph_part, "no such node or edge exists: #{graph_part}")
    end
  end
end
