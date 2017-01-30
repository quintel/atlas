module Atlas
  module GraphHelper
    def make_node(key, attributes = {})
      model = Atlas::Node.new(key: key)
      Refinery::Node.new(key, attributes.merge(model: model))
    end

    def make_edge(from, to, carrier, attributes = {})
      model = Atlas::Edge.new(key: Atlas::Edge.key(from.key, to.key, carrier))
      from.connect_to(to, carrier, attributes.merge(model: model))
    end
  end
end
