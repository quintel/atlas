require 'spec_helper'

module Atlas
  describe Slot::CarrierEfficient do
    let(:node) do
      EnergyNode.new(
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

    context 'when the slot lacks efficiencies' do
      before do
        node.input  = { gas: 0.4, oil: 0.5 }
        node.output = { electricity: { gas: 0.5 } }
      end

      it 'fails validation' do
        expect(slot).not_to be_valid
      end

      it 'informs the user of the error' do
        slot.valid?

        expect(slot.errors.full_messages).
          to include('electricity slot lacks efficiency ' \
                     'data for oil')
      end
    end

    context 'when the slot lacks input shares' do
      before do
        node.input  = { gas: 0.4 }
        node.output = { electricity: { gas: 0.5, oil: 0.5 } }
      end

      it 'fails validation' do
        expect(slot).not_to be_valid
      end

      it 'informs the user of the error' do
        node.valid?

        expect(slot.errors.full_messages).
          to include('electricity slot lacks input shares ' \
                     'for oil')
      end
    end
  end
end
