# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe EnergyBalance do
    let(:eb) { EnergyBalance.new(:nl) }

    describe '.new' do
      it 'is able to create a new one' do
        expect(-> { EnergyBalance.new }).not_to raise_error
      end

      it 'is by default take the Netherlands and unit = TJ' do
        eb = EnergyBalance.new
        expect(eb.key).to be :nl
        expect(eb.unit).to be :tj
      end
    end

    describe '.find' do
      it 'finds the dutch one' do
        eb = EnergyBalance.find(:nl)
        expect(eb.key).to be :nl
      end

      it 'raises an error when key is invalid' do
        expect { EnergyBalance.find(nil) }.to raise_error InvalidKeyError
      end
    end

    describe '#get' do
      it 'returns correct value for NL when asked for a specific attribute' do
        allow(eb).to receive(:cell).and_return(6)
        expect(eb.get('Residential', 'coal_and_peat')).to be 6.0
      end

      it 'works with other units' do
        eb.unit = :twh
        allow(eb).to receive(:cell).and_return(6)

        expect(eb.get('Residential', 'coal_and_peat'))
          .to eql(EnergyUnit.new(6, :tj).to_unit(:twh))
      end

      it 'raises an error when an unknown unit is requested' do
        eb.unit = :i_do_not_exist
        allow(eb).to receive(:cell).and_return(6)
        expect(-> { eb.get('Residential', 'coal_and_peat') }).to \
          raise_error UnknownUnitError
      end
    end

    describe '#query' do
      it 'returns a value when asked for a specific number' do
        expect(eb.query('residential,coal_and_peat')).not_to be_nil
      end
    end
  end
end
