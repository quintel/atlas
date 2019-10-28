# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe Slot::Elastic do
    let(:node) { Atlas::Node.new(key: :a) }
    let(:slot) { node.out_slots.detect { |slot| slot.carrier == :loss } }

    context 'when the node has multiple elastic slots' do
      before do
        node.output = { loss: :elastic, electricity: :elastic }
      end

      it 'fails validation' do
        expect(slot).not_to be_valid
      end

      it 'informs the user of the error' do
        slot.valid?

        expect(slot.errors.full_messages)
          .to include('cannot have more than one elastic slot')
      end
    end
  end
end
