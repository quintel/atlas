# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a storage price attribute' do |attribute|
  def build_mo(type = nil)
    Atlas::NodeAttributes::ElectricityMeritOrder.new(type: type)
  end

  context 'when the node does not belong to the merit order' do
    it "has an error on #{attribute}" do
      node = described_class.new(attribute => 10.0)

      expect(node.errors_on(attribute)).to include(
        'is only allowed when the merit_order type is "flex"'
      )
    end
  end

  context 'when the node is a flex merit order participant' do
    it 'has an error when the value is -10' do
      node = described_class.new(
        attribute => -10.0,
        merit_order: build_mo(:flex)
      )

      expect(node.errors_on(attribute)).to include('must not be less than zero')
    end

    it 'has no error when the value is 0' do
      node = described_class.new(
        attribute => 0.0,
        merit_order: build_mo(:flex)
      )

      expect(node.errors_on(attribute)).to be_empty
    end

    it 'has no error when the value is 10' do
      node = described_class.new(
        attribute => 10.0,
        merit_order: build_mo(:flex)
      )

      expect(node.errors_on(attribute)).to be_empty
    end

    it 'has no error when the value is nil' do
      node = described_class.new(
        attribute => nil,
        merit_order: build_mo(:flex)
      )

      expect(node.errors_on(attribute)).to be_empty
    end
  end
end

describe Atlas::EnergyNode do
  describe '#all' do
    it 'returns all the subclasses that have been defined' do
      expect(described_class.all.length).to eq(15)
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

  describe '#sustainability_share' do
    let(:node) { described_class.new(key: :test_node).tap(&:save!) }

    before do
      Atlas::Carrier.new(key: :electricity).save(false)

      Atlas::EnergyEdge.new(
        supplier: node.key,
        consumer: :__unused__,
        carrier: :electricity,
        ns: ''
      ).save(false)

      Atlas::EnergyEdge.new(
        supplier: node.key,
        consumer: :__unused__,
        carrier: :loss,
        ns: ''
      ).save(false)
    end

    context 'when the node does not belong to the primary_energy_demand group' do
      it 'may be blank' do
        expect(node.errors_on(:sustainability_share)).to be_empty
      end
    end

    context 'when the node belongs to the primary_energy_demand group and a share is set' do
      before do
        node.groups = [:primary_energy_demand]
        node.sustainability_share = 1.0
      end

      it 'is valid' do
        expect(node.errors_on(:sustainability_share)).to be_empty
      end
    end

    context 'when the node belongs to the primary_energy_demand group and carriers have a ' \
            'sustainable value' do
      before do
        node.groups = [:primary_energy_demand]
        Atlas::Carrier.find(:electricity).sustainable = 1.0
      end

      it 'is valid' do
        expect(node.errors_on(:sustainability_share)).to be_empty
      end
    end

    context 'when the node belongs to the primary_energy_demand group and carriers have no ' \
            'sustainable value' do
      before do
        node.groups = [:primary_energy_demand]
      end

      it 'is valid' do
        expect(node.errors_on(:sustainability_share)).to include(
          'must not be blank on a primary_energy_demand node when one or more output carriers do ' \
          'not define a `sustainable` value'
        )
      end
    end
  end

  describe '#marginal_costs' do
    include_examples 'a storage price attribute', 'marginal_costs'
  end

  describe '#max_consumption_price' do
    include_examples 'a storage price attribute', 'max_consumption_price'
  end
end
