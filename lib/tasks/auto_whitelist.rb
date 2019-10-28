# frozen_string_literal: true

desc <<-DESC
  Whitelists all nodes edges based on a sparse graph
DESC

def add_method(el, method)
  el.graph_methods << method unless el.graph_methods.include?(method)
end

task auto_whitelist: :environment do
  dataset = Atlas::Dataset::Derived.all.last

  dataset.graph.nodes.each do |node|
    # Nodes
    model = node.get(:model)

    node.slots.each do |slots|
      slots.each do |slot|
        next unless slot.get(:share)

        method = (slot.direction == :in ? 'input' : 'output')

        add_method(model, method)
      end
    end

    add_method(model, 'demand') if node.get(:demand)

    add_method(model, 'number_of_units') if node.get(:number_of_units)

    model.save if model.graph_methods.any?

    # Edges
    node.edges(:out).each do |edge|
      model = edge.get(:model)

      add_method(model, 'child_share') if edge.get(:child_share)

      add_method(model, 'parent_share') if edge.get(:parent_share)

      model.save if model.graph_methods.any?
    end
  end
end
