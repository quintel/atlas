require 'spec_helper'

module Tome
  describe Slot::CarrierEfficient do
    let(:node) do
      Node.new(
        key:    :a,
        input:  { gas: 0.4, oil: 0.6 },
        output: { electricity: { gas: 0.5, oil: 0.4 }, loss: :elastic }
      )
    end

    let(:slot) { node.out_slots.detect { |s| s.carrier == :electricity } }

    it 'calculates the share dynamically, according to the input' do
      # 0.4 * 0.5 + 0.6 * 0.4
      expect(slot.share).to eq(0.44)
    end

    it 'changes when the proportion of inputs change' do
      node.input = { gas: 0.6, oil: 0.4 }

      # 0.6 * 0.5 + 0.4 * 0.4
      #
      # More gas, which is more efficient (0.5 as opposed to 0.4), therefore
      # efficiency is higher.
      expect(slot.share).to eq(0.46)
    end

    it 'permits one slot to provide 100% of demand' do
      node.input = { gas: 1.0, oil: 0 }
      expect(slot.share).to eq(0.5)
    end
  end # Slot::CarrierEfficient
end # Tome
