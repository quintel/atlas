# frozen_string_literal: true

require_relative 'node'

module Atlas
  # Describes a Node in the molecules graph.
  class MoleculeNode
    include Node
    directory_name 'graphs/molecules/nodes'
  end
end
