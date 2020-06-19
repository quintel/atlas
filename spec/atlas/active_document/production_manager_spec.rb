require 'spec_helper'

module Atlas::ActiveDocument
  describe ProductionManager do
    let(:manager) do
      ProductionManager.new(Atlas::EnergyNode, { foo: {
        demand: 50,
        output: { coal: 0.812 }
      }})
    end

    let(:production_node) { manager.get(:foo) }

    it 'ignores the original attributes when not present in the export data' do
      expect(production_node.use).to be_nil
    end

    it 'merges in the static, region-specific data' do
      expect(production_node.demand).to eq(50)
    end

    it "doesn't clash with non-production instances" do
      # Load the production node.
      production_node.demand

      non_prod = Atlas::EnergyNode.find(:foo)
      expect(non_prod.demand).to be_nil

      # Fetching the non-production node should not change the production
      # version.
      expect(production_node.demand).to eq(50)
    end

    it 'loads calculated slot data' do
      slot = production_node.out_slots.find { |n| n.carrier == :coal }
      expect(slot.share).to eq(0.812)
    end

    it 'loads edge data' do
      data = { :'foo-bar@coal' => {
        demand: 20, parent_share: 0.385, child_share: 0.411 } }

      edge = ProductionManager.new(Atlas::EnergyEdge, data).get(:'foo-bar@coal')

      expect(edge.demand).to eq(20)
      expect(edge.parent_share).to eq(0.385)
      expect(edge.child_share).to eq(0.411)
    end

    it 'disallows editing the document' do
      expect { production_node.save }.to raise_error(Atlas::ReadOnlyError)

      expect { production_node.update_attributes!(demand: 0) }.
        to raise_error(Atlas::ReadOnlyError)
    end

    it 'disallows deleting the document' do
      expect { production_node.destroy! }.to raise_error(Atlas::ReadOnlyError)
    end
  end
end
