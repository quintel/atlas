require 'spec_helper'

module Atlas::ActiveDocument
  describe ProductionManager, :fixtures do
    let(:manager) { ProductionManager.new(Atlas::Node, :nl) }
    let(:production_node) { manager.get(:foo) }

    it 'keeps the original attributes when not present in the static YML' do
      expect(production_node.use).to eq('energetic')
    end

    it 'merges in the static, region-specific data' do
      expect(production_node.demand).to eq(50)
    end

    it "doesn't clash with non-production instances" do
      # Load the production node.
      production_node.demand

      non_prod = Atlas::Node.find(:foo)
      expect(non_prod.demand).to be_nil

      # Fetching the non-production node should not change the production
      # version.
      expect(production_node.demand).to eq(50)
    end

    it 'loads data by the region code' do
      uk_manager = ProductionManager.new(Atlas::Node, :uk)
      expect(uk_manager.get(:foo).demand).to eq(100)
    end

    it 'loads calculated slot data' do
      slot = production_node.out_slots.find { |n| n.carrier == :coal }
      expect(slot.share).to eql(0.812)
    end

    it 'loads edge data' do
      edge = ProductionManager.new(Atlas::Edge, :nl).get(:'bar-foo@coal')

      expect(edge.demand).to eq(20)
      expect(edge.parent_share).to eql(0.385)
      expect(edge.child_share).to eql(0.411)
    end
  end # ProductionManager
end # Atlas::ActiveDocument
