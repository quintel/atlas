# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Slot::Elastic do
  let(:node) { Atlas::Node.new(key: :a, output: { loss: :elastic }) }
  let(:slot) { node.out_slots.detect { |slot| slot.carrier == :loss } }

  it 'has nil share' do
    expect(slot.share).to be_nil
  end

  it 'has no errors on share' do
    slot.valid?
    expect(slot.errors_on(:share)).not_to include('is not a number')
  end

  it 'is a Slot::Dynamic' do
    expect(slot).to be_a(described_class)
  end

  it 'belongs to a Node' do
    expect(slot.node).to eq(node)
  end

  it 'has a direction determined by the node' do
    expect(slot.direction).to eq(:out)
  end

  it 'has a carrier determined by the node' do
    expect(slot.carrier).to eq(:loss)
  end

  context 'when the node has multiple elastic slots' do
    before do
      node.output = { loss: :elastic, electricity: :elastic }
    end

    it 'fails validation' do
      expect(slot).not_to be_valid
    end

    it 'informs the user of the error' do
      slot.valid?

      expect(slot.errors.full_messages).
        to include('cannot have more than one elastic slot')
    end
  end
end
