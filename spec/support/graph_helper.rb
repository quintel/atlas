module Atlas
  module GraphHelper
    def make_node(key, attributes = {})
      klass = attributes.delete(:class) || Atlas::EnergyNode
      model = klass.new(key: key)

      Refinery::Node.new(key, attributes.merge(model: model))
    end

    def make_edge(from, to, carrier, attributes = {})
      klass = attributes.delete(:class) || Atlas::EnergyEdge
      model = klass.new(key: Edge.key(from.key, to.key, carrier))

      from.connect_to(to, carrier, attributes.merge(model: model))
    end
  end
end
