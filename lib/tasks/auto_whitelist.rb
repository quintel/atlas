desc <<-DESC
  Whitelists all nodes edges based on a sparse graph
DESC

def add_method(el, method)
  unless el.graph_methods.include?(method)
    el.graph_methods << method
  end
end

task auto_whitelist: :environment do
  dataset = Atlas::Dataset::Derived.all.last

  dataset.graph.nodes.each do |node|
    # Nodes
    model = node.get(:model)

    node.slots.each do |slots|
      slots.each do |slot|
        if slot.get(:share)
          method = (slot.direction == :in ? "input" : "output")

          add_method(model, method)
        end
      end
    end

    if node.get(:demand)
      add_method(model, 'demand')
    end

    if node.get(:number_of_units)
      add_method(model, 'number_of_units')
    end

    if model.graph_methods.any?
      model.save
    end

    # Edges
    node.edges(:out).each do |edge|
      model = edge.get(:model)

      if edge.get(:child_share)
        add_method(model, 'child_share')
      end

      if edge.get(:parent_share)
        add_method(model, 'parent_share')
      end

      if model.graph_methods.any?
        model.save
      end
    end
  end
end
