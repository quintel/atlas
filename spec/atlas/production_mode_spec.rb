require 'spec_helper'

module Atlas
  describe ProductionMode, :fixtures do
    let(:mode) { ProductionMode.new({ nodes: { foo: { demand: 50 } } }) }

    it 'retrieves nodes' do
      expect(mode.nodes.length).to eq(Atlas::Node.all.length)
    end

    it 'uses static data' do
      expect(mode.nodes.find(:foo).demand).to eql(50.0)
    end

    it 'retrieves edges' do
      expect(mode.edges.length).to eq(Atlas::Edge.all.length)
    end
  end # ProductionMode
end # Atlas
