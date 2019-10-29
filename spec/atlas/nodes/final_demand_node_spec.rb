require 'spec_helper'

module Atlas

describe Node::FinalDemand do
  let(:node) { Node.find('fd') }

  describe '#all' do
    it "finds existing stuff" do
      expect(Node::FinalDemand.all.length).not_to eq(0)
    end

    it 'removes the subclass from the key' do
      expect(Node::FinalDemand.find('fd').key.to_s).
        to_not include('.final_demand_node')
    end
  end

  describe '#find' do
    it "finds the fixture" do
      expect(Node::FinalDemand.find('fd')).not_to be_nil
    end
  end

end

end
