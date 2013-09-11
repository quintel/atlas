require 'spec_helper'

module Atlas::ActiveDocument
  describe ProductionManager do
    let(:manager) do
      ProductionManager.new(Atlas::Node, { foo: {
        demand: 50,
        output: { coal: 0.812 }
      }})
    end

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

    it 'loads calculated slot data' do
      slot = production_node.out_slots.find { |n| n.carrier == :coal }
      expect(slot.share).to eql(0.812)
    end

    it 'loads edge data' do
      data = { :'bar-foo@coal' => {
        demand: 20, parent_share: 0.385, child_share: 0.411 } }

      edge = ProductionManager.new(Atlas::Edge, data).get(:'bar-foo@coal')

      expect(edge.demand).to eq(20)
      expect(edge.parent_share).to eql(0.385)
      expect(edge.child_share).to eql(0.411)
    end

    it 'deep-merges hash attributes' do
      manager = ProductionManager.new(Atlas::Node, { fd: {
        input: { coal: 0.7 }
      }})

      expect(manager.get(:fd).input).to eql(corn: 0.5, coal: 0.7)

      # Does not change the original:
      expect(Atlas::Node.find(:fd).input[:coal]).to eq(0.5)
    end

    it 'disallows editing the document' do
      expect { production_node.save }.to raise_error(Atlas::ReadOnlyError)

      expect { production_node.update_attributes!(demand: 0) }.
        to raise_error(Atlas::ReadOnlyError)
    end

    it 'disallows deleting the document' do
      expect { production_node.destroy! }.to raise_error(Atlas::ReadOnlyError)
    end
  end # ProductionManager
end # Atlas::ActiveDocument
