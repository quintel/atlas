require 'spec_helper'

module Atlas
  describe Slot do
    let(:node) { Node.new(key: :foo) }

    describe 'Creating a input slot' do
      let(:slot) { Slot.new(node: node, direction: :in, carrier: :gas) }

      it { expect(slot.node).to eq(node) }
      it { expect(slot.direction).to eq(:in) }
      it { expect(slot.carrier).to eq(:gas) }
      it { expect(slot.key).to eq(:'foo+@gas') }
    end # Creating an input slot

    describe 'Creating a output slot' do
      let(:slot) do
        Slot.new(node: node, direction: :out, carrier: :electricity)
      end

      it { expect(slot.node).to eq(node) }
      it { expect(slot.direction).to eq(:out) }
      it { expect(slot.carrier).to eq(:electricity) }
      it { expect(slot.key).to eq(:'foo-@electricity') }
    end # Creating an output slot

    describe 'setting the node' do
      let(:slot)     { Slot.new(node: node, direction: :out, carrier: :gas) }
      let(:new_node) { Node.new(key: :bar) }

      before { slot.node = new_node }

      it 'sets the node' do
        expect(slot.node).to eql(new_node)
      end

      it 'changes the key' do
        expect(slot.key).to eql(:'bar-@gas')
      end
    end # setting the node

    describe 'setting the direction' do
      describe 'to in' do
        let(:slot) { Slot.new(node: node, direction: :out, carrier: :gas) }
        before { slot.direction = :in }

        it 'sets the direction' do
          expect(slot.direction).to eql(:in)
        end

        it 'changes the key' do
          expect(slot.key).to eql(:'foo+@gas')
        end
      end # to in

      describe 'to out' do
        let(:slot) { Slot.new(node: node, direction: :in, carrier: :gas) }
        before { slot.direction = :out }

        it 'sets the direction' do
          expect(slot.direction).to eql(:out)
        end

        it 'changes the key' do
          expect(slot.key).to eql(:'foo-@gas')
        end
      end # to in
    end # setting the direction
  end # Slot
end # Atlas
