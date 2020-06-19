# frozen_string_literal: true

require 'spec_helper'

describe Atlas::EnergyNode do
  describe '#all' do
    it 'returns all the subclasses that have been defined' do
      expect(described_class.all.length).to eq(7)
    end
  end

  describe '#find' do
    it 'returns a node in its right class' do
      expect(described_class.find('foo')).to be_a(Atlas::EnergyNode::Converter)
    end
  end

  describe 'fever' do
    let(:fever) do
      Atlas::NodeAttributes::Fever.new(
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

    let(:node) { described_class.new(fever: fever, input: input) }

    context 'with an efficiency_based_on and efficiency_balanced_with' do
      it 'has no errors' do
        expect(node.errors_on(:fever)).to be_empty
      end
    end

    context 'when the efficiency_based_on slot is missing' do
      let(:input) { { ambient_heat: 0.5 } }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_based_on expects a electricity slot, but none was present'
        )
      end
    end

    context 'when the efficiency_balanced_with slot is missing' do
      let(:input) { { electricity: 0.5 } }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_balanced_with expects a ambient_heat slot, but none was present'
        )
      end
    end

    context 'when the efficiency_balanced_with value is missing' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(efficiency_based_on: :electricity)
      end

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.efficiency_balanced_with must not be blank when ' \
          'fever.efficiency_based_on is set'
        )
      end
    end

    describe 'when alias_of referenecs a non-existent node' do
      let(:fever) { Atlas::NodeAttributes::Fever.new(alias_of: :no) }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.alias_of must be the name of a Fever node'
        )
      end
    end

    context 'when alias_of references a non-Fever node' do
      let(:fever) { Atlas::NodeAttributes::Fever.new(alias_of: :my_residence) }

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.alias_of must be the name of a Fever node'
        )
      end
    end

    context 'when alias_of references a space heating node' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(alias_of: :fever_space_heat_producer)
      end

      it 'has an error' do
        expect(node.errors_on(:fever)).to include(
          'fever.alias_of must be the name of a hot water node'
        )
      end
    end

    context 'when alias_of references a hot water node' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(alias_of: :fever_hot_water_producer)
      end

      it 'has no errors' do
        expect(node.errors_on(:fever)).to be_empty
      end
    end

    context 'when assigning capacity on a "hybrid" node' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(capacity: { electricity: 1.0 })
      end

      let(:node) { described_class.new(key: :abc_hybrid, fever: fever) }

      it 'permits the attribute having a value' do
        expect(node.errors_on(:fever)).to be_empty
      end

      it 'denies the attribute being empty' do
        fever.capacity.delete(:electricity)

        expect(node.errors_on(:fever))
          .to include('fever.capacity must be set on a hybrid node')
      end

      it 'denies the attribute being nil' do
        node.fever = Atlas::NodeAttributes::Fever.new

        expect(node.errors_on(:fever))
          .to include('fever.capacity must be set on a hybrid node')
      end
    end

    context 'when assigning capacity on a non-variable-efficiency node' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(capacity: { electricity: 1.0 })
      end

      let(:node) { described_class.new(key: :abc, fever: fever) }

      it 'denies the attribute having a value' do
        expect(node.errors_on(:fever)).to include(
          'fever.capacity requires fever.efficiency_based_on to be present'
        )
      end
    end

    context 'when using capacity and the variable-efficiency capacity is not specified' do
      let(:fever) do
        Atlas::NodeAttributes::Fever.new(
          capacity: { electricity: 1.0 },
          efficiency_based_on: :network_gas
        )
      end

      let(:node) { described_class.new(key: :abc, fever: fever) }

      it 'denies the attribute having a value' do
        expect(node.errors_on(:fever))
          .to include('fever.capacity.network_gas must not be blank')
      end
    end
  end

  describe 'waste_outputs' do
    context 'when the node has an output slot of the correct type' do
      let(:node) do
        described_class.new(
          output: { electricity: 1.0 },
          waste_outputs: [:electricity]
        )
      end

      it 'has no error on waste_outputs' do
        expect(node.errors_on(:waste_outputs)).to be_blank
      end
    end

    context 'when the node has no output slot of the correct type' do
      let(:node) do
        described_class.new(
          output: { gas: 1.0 },
          waste_outputs: [:electricity]
        )
      end

      it 'has an error on waste_outputs' do
        expect(node.errors_on(:waste_outputs))
          .to include('includes a non-existent output carrier: electricity')
      end
    end

    context 'when loss is used as a waste_output' do
      let(:node) do
        described_class.new(
          output: { electricity: 0.9, loss: 0.1 },
          waste_outputs: [:loss]
        )
      end

      it 'has an error on waste_outputs' do
        expect(node.errors_on(:waste_outputs))
          .to include('must not include loss')
      end
    end

    context 'when the value is empty' do
      let(:node) { described_class.new(waste_outputs: []) }

      it 'has no error on waste_outputs' do
        expect(node.errors_on(:waste_outputs)).to be_blank
      end
    end

    context 'when the value is nil' do
      let(:node) { described_class.new(waste_outputs: nil) }

      it 'has no error on waste_outputs' do
        expect(node.errors_on(:waste_outputs)).to be_blank
      end
    end
  end
end
