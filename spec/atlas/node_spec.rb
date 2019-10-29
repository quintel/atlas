require 'spec_helper'

module Atlas

describe Node do
  describe '#out_slots' do
    context 'when the node has no "output" data' do
      let(:node) { Node.new(key: :a) }

      it 'has no output slots'
    end

    context 'when the node has a single "output" pair' do
      let(:node) { Node.new(key: :a, output: { gas: 0.4 }) }

      it 'contains a single slot' do
        expect(node.out_slots.length).to eq(1)
      end

      it 'sets the slot direction' do
        expect(node.out_slots.first.direction).to eq(:out)
      end

      it 'sets the slot node' do
        expect(node.out_slots.first.node).to eq(node)
      end

      it 'sets the slot share' do
        expect(node.out_slots.first.share).to eq(0.4)
      end

      it 'sets the slot carrier' do
        expect(node.out_slots.first.carrier).to eq(:gas)
      end
    end

    context 'when creating an "elastic" slot' do
      it 'creates a Slot::Elastic when the share is :elastic' do
        node = Node.new(key: :a, output: { gas: :elastic })
        expect(node.out_slots.first).to be_a(Slot::Elastic)
      end

      it 'creates a Slot::Elastic when the share is "elastic"' do
        node = Node.new(key: :a, output: { gas: 'elastic' })
        expect(node.out_slots.first).to be_a(Slot::Elastic)
      end
    end

    context 'when the node has gas and oil "output" pairs' do
      let(:node) { Node.new(key: :a, output: { gas: 0.3, oil: 0.7 }) }

      it 'contains two slots' do
        expect(node.out_slots.length).to eq(2)
      end

      it 'sets the gas slot direction' do
        expect(node.out_slots.to_a.first.direction).to eq(:out)
      end

      it 'sets the gas slot node' do
        expect(node.out_slots.to_a.first.node).to eq(node)
      end

      it 'sets the gas slot share' do
        expect(node.out_slots.to_a.first.share).to eq(0.3)
      end

      it 'sets the gas slot carrier' do
        expect(node.out_slots.to_a.first.carrier).to eq(:gas)
      end

      it 'sets the oil slot direction' do
        expect(node.out_slots.to_a.last.direction).to eq(:out)
      end

      it 'sets the oil slot node' do
        expect(node.out_slots.to_a.last.node).to eq(node)
      end

      it 'sets the oil slot share' do
        expect(node.out_slots.to_a.last.share).to eq(0.7)
      end

      it 'sets the oil slot carrier' do
        expect(node.out_slots.to_a.last.carrier).to eq(:oil)
      end
    end

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
        expect(node.out_slots.find { |slot| slot.carrier == :elec }).not_to be
      end

      it 'adds slots which were added' do
        expect(node.out_slots.length).to eq(2)

        new_slot = node.out_slots.to_a.last

        expect(new_slot.carrier).to eq(:oil)
        expect(new_slot.share).to eq(0.6)
      end
    end
  end

  describe '#in_slots' do
    context 'when the node has no "input" data' do
      let(:node) { Node.new(key: :a) }

      it 'has no input slots'
    end

    context 'when the node has a single "input" pair' do
      let(:node) { Node.new(key: :a, input: { gas: 0.4 }) }

      it 'contains a single slot' do
        expect(node.in_slots.length).to eq(1)
      end

      it 'sets the slot direction' do
        expect(node.in_slots.first.direction).to eq(:in)
      end

      it 'sets the slot node' do
        expect(node.in_slots.first.node).to eq(node)
      end

      it 'sets the slot share' do
        expect(node.in_slots.first.share).to eq(0.4)
      end

      it 'sets the slot carrier' do
        expect(node.in_slots.first.carrier).to eq(:gas)
      end
    end

    context 'when creating an "elastic" slot' do
      let(:node) { Node.new(key: :a, input: { gas: :elastic }) }

      it 'sets no share on the slot' do
        expect(node.in_slots.first.share).to be_nil
      end
    end

    context 'when the node has gas and oil "input" pairs' do
      let(:node) { Node.new(key: :a, input: { gas: 0.3, oil: 0.7 }) }

      it 'contains two slots' do
        expect(node.in_slots.length).to eq(2)
      end

      it 'sets the gas slot direction' do
        expect(node.in_slots.to_a.first.direction).to eq(:in)
      end

      it 'sets the gas slot node' do
        expect(node.in_slots.to_a.first.node).to eq(node)
      end

      it 'sets the gas slot share' do
        expect(node.in_slots.to_a.first.share).to eq(0.3)
      end

      it 'sets the gas slot carrier' do
        expect(node.in_slots.to_a.first.carrier).to eq(:gas)
      end

      it 'sets the oil slot direction' do
        expect(node.in_slots.to_a.last.direction).to eq(:in)
      end

      it 'sets the oil slot node' do
        expect(node.in_slots.to_a.last.node).to eq(node)
      end

      it 'sets the oil slot share' do
        expect(node.in_slots.to_a.last.share).to eq(0.7)
      end

      it 'sets the oil slot carrier' do
        expect(node.in_slots.to_a.last.carrier).to eq(:oil)
      end
    end

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
        expect(node.in_slots.find { |slot| slot.carrier == :elec }).not_to be
      end

      it 'adds slots which were added' do
        expect(node.in_slots.length).to eq(2)

        new_slot = node.in_slots.to_a.last

        expect(new_slot.carrier).to eq(:oil)
        expect(new_slot.share).to eq(0.6)
      end
    end
  end

  describe '#all' do
    it 'returns all the subclasses that have been defined' do
      expect(Node.all.length).to eq(7)
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

      expect(node.max_demand).to eq('recursive')
      expect(node.errors[:max_demand]).to be_empty
    end

    it 'permits :recursive' do
      node.max_demand = :recursive
      node.valid?

      expect(node.max_demand).to eq(:recursive)
      expect(node.errors[:max_demand]).to be_empty
    end
  end

  describe 'fever' do
    let(:fever) do
      FeverDetails.new(
        efficiency_based_on: :electricity,
        efficiency_balanced_with: :ambient_heat
      )
    end

    let(:attrs) do
      { fever: fever, input: input }
    end

    let(:input) do
      { electricity: 0.5, ambient_heat: 0.5 }
    end

    let(:node) { Node.new(fever: fever, input: input) }

    context 'with an efficiency_based_on and efficiency_balanced_with' do
      it 'has no errors' do
        expect(node.errors_on(:fever)).to be_empty
      end
    end

    context 'when the efficiency_based_on slot is missing' do
      let(:input) { { ambient_heat: 0.5 } }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_based_on expects a electricity slot, but none ' \
          'was present'
        )
      end
    end

    context 'when the efficiency_balanced_with slot is missing' do
      let(:input) { { electricity: 0.5 } }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_balanced_with expects a ambient_heat slot, but ' \
          'none was present'
        )
      end
    end

    context 'when the efficiency_balanced_with value is missing' do
      let(:fever) { FeverDetails.new(efficiency_based_on: :electricity) }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_balanced_with must not be blank when ' \
          'fever.efficiency_based_on is set'
        )
      end
    end

    describe 'alias_of' do
      context 'pointing at a non-existent node' do
        let(:fever) { FeverDetails.new(alias_of: :no) }

        it 'has an error' do
          expect(node.errors_on(:fever)).to include(
            'fever.alias_of must be the name of a Fever node'
          )
        end
      end

      context 'pointing at a non-Fever node' do
        let(:fever) { FeverDetails.new(alias_of: :my_residence) }

        it 'has an error' do
          expect(node.errors_on(:fever)).to include(
            'fever.alias_of must be the name of a Fever node'
          )
        end
      end

      context 'pointing at a space heating node' do
        let(:fever) { FeverDetails.new(alias_of: :fever_space_heat_producer) }

        it 'has an error' do
          expect(node.errors_on(:fever)).to include(
            'fever.alias_of must be the name of a hot water node'
          )
        end
      end

      context 'pointing at a hot water node' do
        let(:fever) { FeverDetails.new(alias_of: :fever_hot_water_producer) }

        it 'has no errors' do
          expect(node.errors_on(:fever)).to be_empty
        end
      end
    end

    describe 'capacity' do
      context 'on a "hybrid" node' do
        let(:fever) { Atlas::FeverDetails.new(capacity: { electricity: 1.0 }) }
        let(:node) { Atlas::Node.new(key: :abc_hybrid, fever: fever) }

        it 'permits the attribute having a value' do
          expect(node.errors_on(:fever)).to be_empty
        end

        it 'denies the attribute being empty' do
          fever.capacity.delete(:electricity)

          expect(node.errors_on(:fever))
            .to include('fever.capacity must be set on a hybrid node')
        end

        it 'denies the attribute being nil' do
          node.fever = FeverDetails.new

          expect(node.errors_on(:fever))
            .to include('fever.capacity must be set on a hybrid node')
        end
      end

      context 'on a non-variable-efficiency node' do
        let(:fever) { Atlas::FeverDetails.new(capacity: { electricity: 1.0 }) }
        let(:node) { Atlas::Node.new(key: :abc, fever: fever) }

        it 'denies the attribute having a value' do
          expect(node.errors_on(:fever)).to include(
            'fever.capacity requires fever.efficiency_based_on to be present'
          )
        end
      end

      context 'when the variable-efficiency capacity is not specified' do
        let(:fever) do
          Atlas::FeverDetails.new(
            capacity: { electricity: 1.0 },
            efficiency_based_on: :network_gas
          )
        end

        let(:node) { Atlas::Node.new(key: :abc, fever: fever) }

        it 'denies the attribute having a value' do
          expect(node.errors_on(:fever))
            .to include('fever.capacity.network_gas must not be blank')
        end
      end
    end
  end

end

end
