require 'spec_helper'

module Atlas
  describe Slot::Elastic do
    let(:node) { Atlas::Node.new(key: :a) }
    let(:slot) { node.out_slots.detect { |slot| slot.carrier == :loss } }

    context 'as the only output slot' do
      before { node.output = { loss: :elastic } }

      it 'has a share of 1.0' do
        expect(slot.share).to eq(1.0)
      end
    end # as the only output slot

    context 'when two other output slots have a share of 0.8' do
      before do
        node.output = { electricity: 0.5, gas: 0.3, loss: :elastic }
      end

      it 'has a share of 0.2' do
        expect(slot.share).to be_within(1e-6).of(0.2)
      end
    end # when two other output slots have a share of 0.7

    context 'when two other output slots have a share of 1.0' do
      before do
        node.output = { electricity: 0.4, gas: 0.6, loss: :elastic }
      end

      it 'has a share of 0' do
        expect(slot.share).to be_zero
      end
    end # when two other output slots have a share of 1.0

    context 'when one other output slot has a share of 1.1' do
      before do
        node.output = { electricity: 1.1, loss: :elastic }
      end

      it 'has a share of 0' do
        expect(slot.share).to be_zero
      end
    end # when one other output slot has a share of 1.1

    context 'when the node has multiple elastic slots' do
      before do
        node.output = { loss: :elastic, electricity: :elastic }
      end

      it 'fails validation' do
        expect(slot).to_not be_valid
      end

      it 'informs the user of the error' do
        slot.valid?

        expect(slot.errors.full_messages).
          to include('cannot have more than one elastic slot')
      end
    end # when the node has multiple elastic slots
  end # Slot::Elastic
end # Atlas
