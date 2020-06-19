require 'spec_helper'

describe Atlas::EnergyNode::FinalDemand do
  let(:node) { Atlas::EnergyNode.find('fd') }

  describe '#all' do
    it 'finds existing records' do
      expect(described_class.all.length).not_to eq(0)
    end

    it 'removes the subclass from the key' do
      expect(described_class.find('fd').key.to_s).not_to include('.final_demand_node')
    end
  end

  describe '#find' do
    it 'finds the fixture' do
      expect(described_class.find('fd')).not_to be_nil
    end
  end
end
