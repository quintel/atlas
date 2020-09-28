# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe 'Runner::ZeroMoleculeNodes' do
    let(:left) { Refinery::Node.new(:left, model: Atlas::MoleculeNode.new(key: :left)) }
    let(:mid) { Refinery::Node.new(:mid, model: Atlas::MoleculeNode.new(key: :mid)) }
    let(:right) { Refinery::Node.new(:right, model: Atlas::MoleculeNode.new(key: :right)) }
    let(:energy) { Refinery::Node.new(:energy, model: Atlas::EnergyNode.new(key: :energy)) }

    let(:graph) do
      graph = Turbine::Graph.new

      graph.add(left)
      graph.add(mid)
      graph.add(right)
      graph.add(energy)

      right.connect_to(mid, :co2)
      mid.connect_to(left, :co2)

      graph
    end

    context 'when molecule nodes have no demands assigned' do
      before do
        Runner::ZeroMoleculeNodes.call(graph)
      end

      it 'sets demand to zero on a left-leaf node' do
        expect(left.demand).to eq(0)
      end

      it 'sets demand to zero on a right-leaf node' do
        expect(right.demand).to eq(0)
      end

      it 'sets demands to zero on the connecting node' do
        expect(mid.demand).to eq(0)
      end

      it 'does not assign demand to an energy leaf node' do
        expect(energy.demand).to be_nil
      end
    end

    context 'when a molecule left-leaf has a demand assigned' do
      before do
        left.set(:demand, 10.0)
        Runner::ZeroMoleculeNodes.call(graph)
      end

      it 'does overwrite demand on the node with zero' do
        expect(left.demand).to eq(0)
      end
    end
  end
end
