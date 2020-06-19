require 'spec_helper'

module Atlas
  describe Slot do
    let(:node) { EnergyNode.new(key: :foo) }

    describe '#share' do
      context 'when the slot is an output' do
        let(:node) do
          EnergyNode.new(
            key: :foo,
            input: { electricity: 0.25 },
            output: { electricity: 0.5 }
          )
        end

        let(:slot) do
          node.out_slots.detect { |slot| slot.carrier == :electricity }
        end

        it 'is determined by the EnergyNode output attribute' do
          expect(slot.share).to eq(0.5)
        end
      end

      context 'when the slot is an input' do
        let(:node) do
          EnergyNode.new(
            key: :foo,
            input: { electricity: 0.25 },
            output: { electricity: 0.5 }
          )
        end

        let(:slot) do
          node.in_slots.detect { |slot| slot.carrier == :electricity }
        end

        it 'is determined by the EnergyNode input attribute' do
          expect(slot.share).to eq(0.25)
        end

        it 'must have a numeric share' do
          node.input[:electricity] = :elastic
          slot.valid?

          expect(slot.errors_on(:share)).to include('is not a number')
        end

        it 'may have a nil share' do
          node.input[:electricity] = nil
          slot.valid?

          expect(slot.errors_on(:share)).not_to include('is not a number')
        end
      end
    end

    describe 'Creating a input slot' do
      let(:slot) { Slot.new(node: node, direction: :in, carrier: :gas) }

      it { expect(slot.node).to eq(node) }
      it { expect(slot.direction).to eq(:in) }
      it { expect(slot.carrier).to eq(:gas) }
      it { expect(slot.key).to eq(:'foo+@gas') }
    end

    describe 'Creating a output slot' do
      let(:slot) do
        Slot.new(node: node, direction: :out, carrier: :electricity)
      end

      it { expect(slot.node).to eq(node) }
      it { expect(slot.direction).to eq(:out) }
      it { expect(slot.carrier).to eq(:electricity) }
      it { expect(slot.key).to eq(:'foo-@electricity') }
    end

    describe 'setting the node' do
      let(:slot)     { Slot.new(node: node, direction: :out, carrier: :gas) }
      let(:new_node) { EnergyNode.new(key: :bar) }

      before { slot.node = new_node }

      it 'sets the node' do
        expect(slot.node).to eq(new_node)
      end

      it 'changes the key' do
        expect(slot.key).to eq(:'bar-@gas')
      end
    end

    describe 'setting the direction' do
      describe 'to in' do
        let(:slot) { Slot.new(node: node, direction: :out, carrier: :gas) }
        before { slot.direction = :in }

        it 'sets the direction' do
          expect(slot.direction).to eq(:in)
        end

        it 'changes the key' do
          expect(slot.key).to eq(:'foo+@gas')
        end
      end

      describe 'to out' do
        let(:slot) { Slot.new(node: node, direction: :in, carrier: :gas) }
        before { slot.direction = :out }

        it 'sets the direction' do
          expect(slot.direction).to eq(:out)
        end

        it 'changes the key' do
          expect(slot.key).to eq(:'foo-@gas')
        end
      end
    end
  end
end
