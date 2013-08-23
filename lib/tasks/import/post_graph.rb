namespace :import do
  # A hidden task which needs to run after importing the nodes, slots, and
  # edges to "fix" the keys of any RDR nodes.
  task :post_graph, [:from, :to] => [:setup] do |_, args|
    Atlas::Node.all.each do |node|
      if node.key.to_s.match(/_rdr$/)
        node.key = node.key.to_s.gsub(/_rdr$/, '').to_sym
        node.save
      end
    end

    Atlas::Edge.all.each do |edge|
      if edge.supplier.to_s.match(/_rdr$/) ||
            edge.consumer.to_s.match(/_rdr$/)
        edge.supplier = edge.supplier.to_s.gsub(/_rdr$/, '').to_sym
        edge.consumer = edge.consumer.to_s.gsub(/_rdr$/, '').to_sym
        edge.save
      end
    end
  end # task :post_graph
end # namespace :import
