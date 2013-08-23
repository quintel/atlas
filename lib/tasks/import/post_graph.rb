namespace :import do
  # A hidden task which needs to run after importing the nodes, slots, and
  # edges to "fix" the keys of any RDR nodes.
  task :post_graph, [:from, :to] => [:setup] do |_, args|
    Atlas::ActiveDocument::Manager.clear_all!

    # Iterating through keys is silly, but documents are not being
    # consistently renamed when doing +Collection.all.each+.

    # Nodes
    # -----

    keys = Atlas::Node.all.map(&:key).map(&:to_s)

    keys.select { |k| k.match(/_rdr$/) }.each do |key|
      node = Atlas::Node.find(key)
      node.key = node.key.to_s.gsub(/_rdr$/, '').to_sym
      node.save(false)
    end

    # Edges
    # -----

    keys = Atlas::Edge.all.map { |e| e.key.to_s }

    keys.select { |k| k.match(/_rdr/) }.each do |key|
      edge = Atlas::Edge.find(key)
      edge.key = edge.key.to_s.gsub(/_rdr/, '').to_sym
      edge.save(false)
    end
  end # task :post_graph
end # namespace :import
