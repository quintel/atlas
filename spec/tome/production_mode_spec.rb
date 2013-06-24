require 'spec_helper'

module Tome
  describe ProductionMode, :fixtures do
    let(:mode) { ProductionMode.new(:nl) }

    it 'retrieves nodes' do
      expect(mode.nodes.length).to eq(Tome::Node.all.length)
    end

    it 'uses static data' do
      expect(mode.nodes.find(:foo).demand).to eq(50)
    end

    it 'retrieves edges' do
      expect(mode.edges.length).to eq(Tome::Edge.all.length)
    end
  end # ProductionMode
end # Tome
