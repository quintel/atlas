require 'spec_helper'

module Tome
  describe Slot::Elastic do
    let(:node) { Tome::Node.new(key: :a) }
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
  end # Slot::Elastic
end # Tome
