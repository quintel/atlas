require 'spec_helper'

module Atlas
  describe EnergyBalance do
    let(:eb) { EnergyBalance.new(:nl) }

    describe '.new' do
      it 'should be able to create a new one' do
        expect(-> { EnergyBalance.new } ).to_not raise_error
      end

      it 'should be by default take the Netherlands and unit = TJ' do
        eb = EnergyBalance.new
        expect(eb.key).to eql :nl
        expect(eb.unit).to eql :tj
      end
    end # .new

    describe '.find' do
      it 'finds the dutch one' do
        eb = EnergyBalance.find(:nl)
        expect(eb.key).to eql :nl
      end

      it 'raises an error when key is invalid' do
        expect { EnergyBalance.find(nil) }.to raise_error InvalidKeyError
      end
    end # .find

    describe '#get' do
      it 'returns correct value for NL when asked for a specific attribute' do
        allow(eb).to receive(:cell).and_return(6)
        expect(eb.get('Residential','coal_and_peat')).to eql 6.0
      end

      it 'works with other units' do
        eb.unit = :twh
        allow(eb).to receive(:cell).and_return(6)

        expect(eb.get('Residential','coal_and_peat')).
          to eql(EnergyUnit.new(6, :tj).to_unit(:twh))
      end

      it 'raises an error when an unknown unit is requested' do
        eb.unit = :i_do_not_exist
        allow(eb).to receive(:cell).and_return(6)
        expect(->{ eb.get('Residential','coal_and_peat') }).to \
          raise_error UnknownUnitError
      end
    end # get

    describe '#query' do
      it 'returns a value when asked for a specific number' do
        expect(eb.query('residential,coal_and_peat')).to_not be_nil
      end
    end # query
  end # EnergyBalance
end # Atlas
