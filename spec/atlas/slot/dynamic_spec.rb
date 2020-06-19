# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Slot::Dynamic do
  let(:node) do
    Atlas::EnergyNode.new(output: { electricity: :etengine_dynamic })
  end

  let(:slot) do
    node.out_slots.detect { |slot| slot.carrier == :electricity }
  end

  it 'has nil share' do
    expect(slot.share).to be_nil
  end

  it 'is a Slot::Dynamic' do
    expect(slot).to be_a(described_class)
  end

  it 'belongs to an EnergyNode' do
    expect(slot.node).to eq(node)
  end

  it 'has a direction determined by the node' do
    expect(slot.direction).to eq(:out)
  end

  it 'has a carrier determined by the node' do
    expect(slot.carrier).to eq(:electricity)
  end
end
