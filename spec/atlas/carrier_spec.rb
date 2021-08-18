# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Carrier do
  it 'loads some fixtures' do
    expect(described_class.all.length).not_to eq(0)
  end

  describe '#queries' do
    context 'with no carrier key' do
      it 'has no default queries'
    end

    context 'with a carrier key' do
      let(:carrier) { described_class.new(key: 'my_carrier') }

      it 'has a default query for co2_conversion_per_mj' do
        expect(carrier.queries[:co2_conversion_per_mj])
          .to eq('CARRIER(my_carrier, co2_conversion_per_mj)')
      end

      it 'has a default query for cost_per_mj' do
        expect(carrier.queries[:cost_per_mj])
          .to eq('CARRIER(my_carrier, cost_per_mj)')
      end

      it 'has a default query for potential_co2_conversion_per_mj' do
        expect(carrier.queries[:potential_co2_conversion_per_mj])
          .to eq('CARRIER(my_carrier, potential_co2_conversion_per_mj)')
      end
    end

    context 'with a persisted carrier and no queries' do
      let(:carrier) do
        doc = described_class.new(key: 'my_carrier', queries: {})
        doc.save!

        Atlas::ActiveDocument::Manager.clear_all!
        described_class.find('my_carrier')
      end

      it 'has a no query for co2_conversion_per_mj' do
        expect(carrier.queries).to eq({})
      end

      it 'allows setting a query for co2_conversion_per_mj' do
        carrier.queries[:co2_conversion_per_mj] = 'hello'
        expect(carrier.queries).to eq(co2_conversion_per_mj: 'hello')
      end

      it 'persists a changed query' do
        carrier.queries[:co2_conversion_per_mj] = 'hello'
        carrier.save!
        Atlas::ActiveDocument::Manager.clear_all!

        expect(described_class.find('my_carrier').queries).to eq(
          co2_conversion_per_mj: 'hello'
        )
      end
    end

    context 'with a custom query for co2_conversion_per_mj' do
      it 'keeps the custom query' do
        carrier = described_class.new(key: 'my_carrier', queries: { co2_conversion_per_mj: '10' })
        expect(carrier.queries[:co2_conversion_per_mj]).to eq('10')
      end
    end

    context 'with a custom value for co2_conversion_per_mj' do
      it 'does not have a default query' do
        carrier = described_class.new(key: 'my_carrier', co2_conversion_per_mj: 15.0)
        expect(carrier.queries[:co2_conversion_per_mj]).to be_nil
      end
    end
  end

  describe '#fallback_price' do
    it 'must be blank when the carrier key is not electricity' do
      expect(
        described_class.new(key: :gas, fallback_price: 10.0).errors_on(:fallback_price)
      ).to include('can only be set on the "electricity" carrier')
    end

    it 'must be blank when the carrier key is blank' do
      expect(
        described_class.new(fallback_price: 10.0).errors_on(:fallback_price)
      ).to include('can only be set on the "electricity" carrier')
    end

    it 'may be present when the carrier key is electricity' do
      expect(
        described_class.new(key: :electricity, fallback_price: 10.0).errors_on(:fallback_price)
      ).to be_empty
    end
  end
end
