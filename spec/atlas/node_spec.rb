# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'a slot collection' do
  def collection
    node.public_send(collection_name)
  end

  context 'when the node has no data' do
    let(:node) { klass.new(key: :a) }

    it 'has no output slots' do
      expect(collection.length).to eq(0)
    end
  end

  context 'when the node has a single slot' do
    let(:node) { klass.new(key: :a, direction => { gas: 0.4 }) }

    it 'contains a single slot' do
      expect(collection.length).to eq(1)
    end

    it 'sets the slot direction' do
      expect(collection.first.direction).to eq(:out)
    end

    it 'sets the slot node' do
      expect(collection.first.node).to eq(node)
    end

    it 'sets the slot share' do
      expect(collection.first.share).to eq(0.4)
    end

    it 'sets the slot carrier' do
      expect(collection.first.carrier).to eq(:gas)
    end
  end

  context 'when the node has gas and oil slots' do
    let(:node) { klass.new(key: :a, direction => { gas: 0.3, oil: 0.7 }) }

    it 'contains two slots' do
      expect(collection.length).to eq(2)
    end

    it 'sets the gas slot direction' do
      expect(collection.to_a.first.direction).to eq(:out)
    end

    it 'sets the gas slot node' do
      expect(collection.to_a.first.node).to eq(node)
    end

    it 'sets the gas slot share' do
      expect(collection.to_a.first.share).to eq(0.3)
    end

    it 'sets the gas slot carrier' do
      expect(collection.to_a.first.carrier).to eq(:gas)
    end

    it 'sets the oil slot direction' do
      expect(collection.to_a.last.direction).to eq(:out)
    end

    it 'sets the oil slot node' do
      expect(collection.to_a.last.node).to eq(node)
    end

    it 'sets the oil slot share' do
      expect(collection.to_a.last.share).to eq(0.7)
    end

    it 'sets the oil slot carrier' do
      expect(collection.to_a.last.carrier).to eq(:oil)
    end
  end

  context 'when updating the "output" data' do
    let(:node) { klass.new(key: :a, direction => { gas: 0.9, elec: 0.1 }) }

    before do
      collection
      node.public_send(:"#{direction}=", gas: 0.4, oil: 0.6)
    end

    context 'when a slot is still present' do
      let(:slot) { collection.find { |slot| slot.carrier == :gas } }

      it 'retains the old slot objects' do
        expect(slot).not_to be_nil
      end

      it 'sets the new slot share' do
        expect(slot.share).to eq(0.4)
      end
    end

    context 'when a slot has been removed' do
      let(:slot) { collection.find { |slot| slot.carrier == :elec } }

      it 'removes the slot' do
        expect(slot).to be_nil
      end
    end

    context 'when a slot has been added' do
      let(:slot) { collection.find { |slot| slot.carrier == :oil } }

      it 'adds the slot' do
        expect(slot.carrier).to eq(:oil)
      end

      it 'sets the slot share' do
        expect(slot.share).to eq(0.6)
      end
    end
  end
end

# --------------------------------------------------------------------------------------------------

describe Atlas::Node do
  let(:klass) do
    Class.new do
      include Atlas::Node

      def self.name
        'TestNode'
      end

      def inspect
        "#<TestNode #{key.inspect}>"
      end
    end
  end

  describe '#out_slots' do
    it_behaves_like 'a slot collection' do
      let(:collection_name) { :out_slots }
      let(:direction) { :output }
    end

    context 'when creating an "elastic" slot' do
      it 'creates a Slot::Elastic when the share is :elastic' do
        node = klass.new(key: :a, output: { gas: :elastic })
        expect(node.out_slots.first).to be_a(Atlas::Slot::Elastic)
      end

      it 'creates a Slot::Elastic when the share is "elastic"' do
        node = klass.new(key: :a, output: { gas: 'elastic' })
        expect(node.out_slots.first).to be_a(Atlas::Slot::Elastic)
      end
    end

    context 'when creating an "etengine_dynamic" slot' do
      it 'creates a Slot::Elastic when the share is :etengine_dynamic' do
        node = klass.new(key: :a, output: { gas: :etengine_dynamic })
        expect(node.out_slots.first).to be_a(Atlas::Slot::Dynamic)
      end

      it 'creates a Slot::Elastic when the share is "elastic"' do
        node = klass.new(key: :a, output: { gas: 'etengine_dynamic' })
        expect(node.out_slots.first).to be_a(Atlas::Slot::Dynamic)
      end
    end
  end

  describe '#in_slots' do
    it_behaves_like 'a slot collection' do
      let(:collection_name) { :out_slots }
      let(:direction) { :output }
    end
  end

  describe '#sector' do
    it 'is an alias of #ns' do
      expect(klass.new(path: 'energy/a').sector).to eq('energy')
    end
  end

  describe '#sector=' do
    let(:node) { klass.new(key: 'a', sector: 'energy') }

    it 'sets the sector' do
      expect(node.sector).to eq('energy')
    end

    it 'is an alias of #ns=' do
      expect(node.ns).to eq('energy')
    end
  end

  describe 'max_demand=' do
    let(:node) { klass.new }

    context 'when given a numeric value' do
      before { node.max_demand = 50 }

      it 'sets the value' do
        expect(node.max_demand).to eq(50)
      end

      it 'is valid' do
        node.valid?
        expect(node.errors[:max_demand]).to be_empty
      end
    end

    it 'permits "recursive"' do
      node.max_demand = 'recursive'

      node.valid?
      expect(node.errors[:max_demand]).to be_empty
    end

    it 'permits :recursive' do
      node.max_demand = :recursive

      node.valid?
      expect(node.errors[:max_demand]).to be_empty
    end
  end
end
