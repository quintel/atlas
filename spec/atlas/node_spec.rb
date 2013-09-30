require 'spec_helper'

module Atlas

describe Node do
  describe '#out_slots' do
    context 'when the node has no "output" data' do
      let(:node) { Node.new(key: :a) }

      it 'has no output slots'
    end # when the node has no output data

    context 'when the node has a single "output" pair' do
      let(:node) { Node.new(key: :a, output: { gas: 0.4 }) }

      it 'contains a single slot' do
        expect(node.out_slots).to have(1).slots
      end

      it 'sets the slot direction' do
        expect(node.out_slots.first.direction).to eql(:out)
      end

      it 'sets the slot node' do
        expect(node.out_slots.first.node).to eql(node)
      end

      it 'sets the slot share' do
        expect(node.out_slots.first.share).to eq(0.4)
      end

      it 'sets the slot carrier' do
        expect(node.out_slots.first.carrier).to eql(:gas)
      end
    end # when the node has a single "output" pair

    context 'when creating an "elastic" slot' do
      it 'creates a Slot::Elastic when the share is :elastic' do
        node = Node.new(key: :a, output: { gas: :elastic })
        expect(node.out_slots.first).to be_a(Slot::Elastic)
      end

      it 'creates a Slot::Elastic when the share is "elastic"' do
        node = Node.new(key: :a, output: { gas: 'elastic' })
        expect(node.out_slots.first).to be_a(Slot::Elastic)
      end
    end # when creating an "elastic" slot

    context 'when the node has gas and oil "output" pairs' do
      let(:node) { Node.new(key: :a, output: { gas: 0.3, oil: 0.7 }) }

      it 'contains two slots' do
        expect(node.out_slots).to have(2).slots
      end

      it 'sets the gas slot direction' do
        expect(node.out_slots.to_a.first.direction).to eql(:out)
      end

      it 'sets the gas slot node' do
        expect(node.out_slots.to_a.first.node).to eql(node)
      end

      it 'sets the gas slot share' do
        expect(node.out_slots.to_a.first.share).to eq(0.3)
      end

      it 'sets the gas slot carrier' do
        expect(node.out_slots.to_a.first.carrier).to eql(:gas)
      end

      it 'sets the oil slot direction' do
        expect(node.out_slots.to_a.last.direction).to eql(:out)
      end

      it 'sets the oil slot node' do
        expect(node.out_slots.to_a.last.node).to eql(node)
      end

      it 'sets the oil slot share' do
        expect(node.out_slots.to_a.last.share).to eq(0.7)
      end

      it 'sets the oil slot carrier' do
        expect(node.out_slots.to_a.last.carrier).to eql(:oil)
      end
    end # when the node has gas and oil "output" pairs

    context 'when updating the "output" data' do
      let(:node) { Node.new(key: :a, output: { gas: 0.9, elec: 0.1 }) }

      before do
        node.out_slots # Load the old slots.
        node.output = { gas: 0.4, oil: 0.6 }
      end

      it 'retains the old slot objects which are still present' do
        gas = node.out_slots.find { |slot| slot.carrier == :gas }

        expect(gas).to be
        expect(gas.share).to eq(0.4)
      end

      it 'removes slots which were deleted' do
        expect(node.out_slots.find { |slot| slot.carrier == :elec }).to_not be
      end

      it 'adds slots which were added' do
        expect(node.out_slots).to have(2).slots

        new_slot = node.out_slots.to_a.last

        expect(new_slot.carrier).to eql(:oil)
        expect(new_slot.share).to eql(0.6)
      end
    end # when updating the "output" data
  end # out_slots

  describe '#in_slots' do
    context 'when the node has no "input" data' do
      let(:node) { Node.new(key: :a) }

      it 'has no input slots'
    end # when the node has no input data

    context 'when the node has a single "input" pair' do
      let(:node) { Node.new(key: :a, input: { gas: 0.4 }) }

      it 'contains a single slot' do
        expect(node.in_slots).to have(1).slots
      end

      it 'sets the slot direction' do
        expect(node.in_slots.first.direction).to eql(:in)
      end

      it 'sets the slot node' do
        expect(node.in_slots.first.node).to eql(node)
      end

      it 'sets the slot share' do
        expect(node.in_slots.first.share).to eq(0.4)
      end

      it 'sets the slot carrier' do
        expect(node.in_slots.first.carrier).to eql(:gas)
      end
    end # when the node has a single "input" pair

    context 'when creating an "elastic" slot' do
      let(:node) { Node.new(key: :a, input: { gas: :elastic }) }

      it 'sets no share on the slot' do
        expect(node.in_slots.first.share).to be_nil
      end
    end # when creating an "elastic" slot

    context 'when the node has gas and oil "input" pairs' do
      let(:node) { Node.new(key: :a, input: { gas: 0.3, oil: 0.7 }) }

      it 'contains two slots' do
        expect(node.in_slots).to have(2).slots
      end

      it 'sets the gas slot direction' do
        expect(node.in_slots.to_a.first.direction).to eql(:in)
      end

      it 'sets the gas slot node' do
        expect(node.in_slots.to_a.first.node).to eql(node)
      end

      it 'sets the gas slot share' do
        expect(node.in_slots.to_a.first.share).to eq(0.3)
      end

      it 'sets the gas slot carrier' do
        expect(node.in_slots.to_a.first.carrier).to eql(:gas)
      end

      it 'sets the oil slot direction' do
        expect(node.in_slots.to_a.last.direction).to eql(:in)
      end

      it 'sets the oil slot node' do
        expect(node.in_slots.to_a.last.node).to eql(node)
      end

      it 'sets the oil slot share' do
        expect(node.in_slots.to_a.last.share).to eq(0.7)
      end

      it 'sets the oil slot carrier' do
        expect(node.in_slots.to_a.last.carrier).to eql(:oil)
      end
    end # when the node has gas and oil "input" pairs

    context 'when updating the "input" data' do
      let(:node) { Node.new(key: :a, input: { gas: 0.9, elec: 0.1 }) }

      before do
        node.in_slots # Load the old slots.
        node.input = { gas: 0.4, oil: 0.6 }
      end

      it 'retains the old slot objects which are still present' do
        gas = node.in_slots.find { |slot| slot.carrier == :gas }

        expect(gas).to be
        expect(gas.share).to eq(0.4)
      end

      it 'removes slots which were deleted' do
        expect(node.in_slots.find { |slot| slot.carrier == :elec }).to_not be
      end

      it 'adds slots which were added' do
        expect(node.in_slots).to have(2).slots

        new_slot = node.in_slots.to_a.last

        expect(new_slot.carrier).to eql(:oil)
        expect(new_slot.share).to eql(0.6)
      end
    end # when updating the "input" data
  end # in_slots

  describe '#all' do
    it 'returns all the subclasses that have been defined' do
      expect(Node.all).to have(5).nodes
    end
  end

  describe '#find' do
    it 'returns a node in its right class' do
      expect(Node.find('foo')).to be_a(Node::Converter)
    end
  end

  describe '#sector' do
    it 'is an alias of #ns' do
      expect(Node.new(path: 'energy/a').sector).to eq('energy')
    end
  end

  describe '#sector=' do
    let(:node) { Node.new(key: 'a', sector: 'energy') }

    it 'sets the sector' do
      expect(node.sector).to eq('energy')
    end

    it 'is an alias of #ns=' do
      expect(node.ns).to eq('energy')
    end
  end

  describe 'max_demand=' do
    let(:node) { Node.new }

    it 'permits a numeric value' do
      node.max_demand = 50
      node.valid?

      expect(node.max_demand).to eq(50)
      expect(node.errors[:max_demand]).to be_empty
    end

    it 'permits "recursive"' do
      node.max_demand = 'recursive'
      node.valid?

      expect(node.max_demand).to eql('recursive')
      expect(node.errors[:max_demand]).to be_empty
    end

    it 'permits :recursive' do
      node.max_demand = :recursive
      node.valid?

      expect(node.max_demand).to eql(:recursive)
      expect(node.errors[:max_demand]).to be_empty
    end
  end # max_demand=

end #describe Node 

end #module
