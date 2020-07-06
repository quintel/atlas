# frozen_string_literal: true

require_relative 'edge'

module Atlas
  # An edge within the molecule graph. See Edge.
  class MoleculeEdge
    include Edge

    directory_name 'graphs/molecules/edges'

    def self.node_class
      MoleculeNode
    end
  end
end
