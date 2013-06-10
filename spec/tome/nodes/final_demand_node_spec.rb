require 'spec_helper'

module Tome

describe Node::FinalDemandNode, :fixtures do
  let(:node) { Node.find('fd') }

  describe '#all' do
    it "finds existing stuff" do
      expect(Node::FinalDemandNode.all).to have_at_least(1).nodes
    end

    it 'removes the subclass from the key' do
      expect(Node::FinalDemandNode.find('fd').key.to_s).
        to_not include('.final_demand_node')
    end
  end

  describe '#find' do
    it "finds the fixture" do
      expect(Node::FinalDemandNode.find('fd')).to_not be_nil
    end
  end

  describe '#demand' do

    context 'with the Dutch dataset' do

      it 'returns the correct number' do
        expect(node.demand(:nl)).to eql(7460.0 / 1000) # TJ to PJ
      end

    end

    context 'with the UK dataset' do

      it 'returns the correct number' do
        expect(node.demand(:uk)).to eql(3730.0 / 1000) # TJ to PJ
      end

    end

  end

end #describe FinalDemandNode 

end #module
