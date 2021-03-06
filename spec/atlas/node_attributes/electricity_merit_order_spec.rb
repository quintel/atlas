# frozen_string_literal: true

require 'spec_helper'

describe Atlas::NodeAttributes::ElectricityMeritOrder do
  describe '#delegate' do
    it 'returns nil' do
      expect(described_class.new.delegate).to be_nil
    end

    it 'returns a value when one is set' do
      expect(described_class.new(delegate: :hi).delegate).to eq(:hi)
    end
  end

  describe '#production_curtailment' do
    context 'when type=:consumer' do
      let(:mo) do
        described_class.new(type: :consumer, production_curtailment: 0.5)
      end

      it 'must be blank' do
        expect(mo.errors_on(:production_curtailment))
          .to include('must be blank')
      end
    end

    context 'when type=:producer and subtype=:dispatchable' do
      let(:mo) do
        described_class.new(
          type: :producer,
          subtype: :dispatchable,
          production_curtailment: 0.5
        )
      end

      it 'must be blank' do
        expect(mo.errors_on(:production_curtailment))
          .to include('must be blank')
      end
    end

    context 'when type=:producer and subtype=:volatile and curtailment ' \
            'is set' do
      let(:mo) do
        described_class.new(
          type: :producer,
          subtype: :volatile,
          production_curtailment: 0.5
        )
      end

      it 'has no errors' do
        expect(mo.errors_on(:production_curtailment)).to be_empty
      end

      it 'returns the curtailment amount' do
        expect(mo.production_curtailment).to eq(0.5)
      end
    end

    context 'when type=:producer and subtype=:volatile and curtailment ' \
            'is not set' do
      let(:mo) do
        described_class.new(type: :producer, subtype: :volatile)
      end

      it 'has no errors' do
        expect(mo.errors_on(:production_curtailment)).to be_empty
      end

      it 'returns nil' do
        expect(mo.production_curtailment).to be_nil
      end
    end

    context 'when type=:producer and subtype=:must_run' do
      it 'may be present' do
        mo = described_class.new(
          type: :producer,
          subtype: :must_run,
          production_curtailment: 0.5
        )

        expect(mo.errors_on(:production_curtailment)).to be_empty
      end

      it 'may be blank' do
        mo = described_class.new(
          type: :producer,
          subtype: :must_run
        )

        expect(mo.errors_on(:production_curtailment)).to be_empty
      end
    end
  end

  describe '#satisfy_with_dispatchables' do
    context 'when type=:consumer' do
      let(:mo) do
        described_class.new(type: :consumer)
      end

      it 'may be blank' do
        expect(mo.errors_on(:satisfy_with_dispatchables)).to be_blank
      end

      it 'must not have a value' do
        mo.satisfy_with_dispatchables = false

        expect(mo.errors_on(:satisfy_with_dispatchables))
          .to include('is only allowed when type=:flex and subtype=:export')
      end
    end

    context 'when type=:flex and subtype=:storage' do
      let(:mo) do
        described_class.new(type: :flex, subtype: :storage)
      end

      it 'may be blank' do
        expect(mo.errors_on(:satisfy_with_dispatchables)).to be_blank
      end

      it 'must not have a value' do
        mo.satisfy_with_dispatchables = true

        expect(mo.errors_on(:satisfy_with_dispatchables))
          .to include('is only allowed when type=:flex and subtype=:export')
      end
    end

    context 'when type=:flex and subtype=:export' do
      let(:mo) do
        described_class.new(type: :flex, subtype: :export)
      end

      it 'may be blank' do
        expect(mo.errors_on(:satisfy_with_dispatchables)).to be_blank
      end

      it 'may be true' do
        mo.satisfy_with_dispatchables = true
        expect(mo.errors_on(:satisfy_with_dispatchables)).to be_blank
      end

      it 'may be false' do
        mo.satisfy_with_dispatchables = false
        expect(mo.errors_on(:satisfy_with_dispatchables)).to be_blank
      end
    end
  end
end
