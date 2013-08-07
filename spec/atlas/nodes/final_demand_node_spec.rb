require 'spec_helper'

module Atlas

describe Node::FinalDemand, :fixtures do
  let(:node) { Node.find('fd') }

  describe '#all' do
    it "finds existing stuff" do
      expect(Node::FinalDemand.all).to have_at_least(1).nodes
    end

    it 'removes the subclass from the key' do
      expect(Node::FinalDemand.find('fd').key.to_s).
        to_not include('.final_demand_node')
    end
  end

  describe '#find' do
    it "finds the fixture" do
      expect(Node::FinalDemand.find('fd')).to_not be_nil
    end
  end

end # FinalDemand

end # module