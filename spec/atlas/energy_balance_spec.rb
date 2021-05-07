require 'spec_helper'

module Atlas
  describe EnergyBalance do
    let(:eb) { EnergyBalance.new(:nl) }

    describe '.new' do
      it 'should be able to create a new one' do
        expect(-> { EnergyBalance.new } ).not_to raise_error
      end

      it 'should be by default take the Netherlands and unit = TJ' do
        eb = EnergyBalance.new
        expect(eb.key).to eql :nl
        expect(eb.unit).to eql :tj
      end
    end

    describe '.find' do
      it 'raises an error when key is invalid' do
        expect { described_class.find(nil) }.to raise_error(InvalidKeyError)
      end

      context 'when a dataset has an energy_balance.csv file' do
        it 'finds the correct energy balance' do
          eb = EnergyBalance.find(:nl)
          expect(eb.key).to eql :nl
        end
      end

      context 'when a dataset has an energy_balance.open_access.csv file' do
        it 'finds the open access CSV' do
          ds = Atlas::Dataset.find(:nl)

          FileUtils.mv(
            ds.dataset_dir.join('energy_balance.csv'),
            ds.dataset_dir.join('energy_balance.open_access.csv')
          )

          expect(described_class.find(:nl).key).to eq(:nl)
        end
      end

      context 'when a dataset has both enegy balance files' do
        it 'opens the open access CSV' do
          ds = Atlas::Dataset.find(:nl)

          ds.dataset_dir.join('energy_balance.csv').write(
            "o,a,b,c\n" \
            'x,1,2,3'
          )

          ds.dataset_dir.join('energy_balance.open_access.csv').write(
            "o,a,b,c\n" \
            'x,10,20,30'
          )

          balance = described_class.find(:nl)
          expect(balance.get('x', 'a')).to eq(10)
        end
      end

      context 'when using a derived dataset without a custom energy balance' do
        let(:dataset) { Atlas::Dataset.find(:groningen) }

        it 'retrieves the parent balance' do
          expect(described_class.find(dataset.key).path)
            .to eq(dataset.parent.dataset_dir.join('energy_balance.csv'))
        end
      end

      context 'when using a derived dataset without a custom energy balance and parent has an ' \
              'open-access file' do
        let(:dataset) { Atlas::Dataset.find(:groningen) }

        before do
          FileUtils.mv(
            dataset.parent.dataset_dir.join('energy_balance.csv'),
            dataset.parent.dataset_dir.join('energy_balance.open_access.csv')
          )
        end

        it 'retrieves the parent balance' do
          expect(described_class.find(dataset.key).path)
            .to eq(dataset.parent.dataset_dir.join('energy_balance.open_access.csv'))
        end
      end

      context 'when using a derived dataset with a custom energy_balance.csv' do
        let(:dataset) { Atlas::Dataset.find(:groningen) }

        before do
          dataset.dataset_dir.join('energy_balance.csv').write(
            "o,a,b,c\n" \
            'x,1,2,3'
          )
        end

        it 'retrieves the parent balance' do
          expect(described_class.find(dataset.key).path)
            .to eq(dataset.dataset_dir.join('energy_balance.csv'))
        end
      end

      context 'when using a derived dataset with a custom energy_balance.open_access.csv' do
        let(:dataset) { Atlas::Dataset.find(:groningen) }

        before do
          dataset.dataset_dir.join('energy_balance.open_access.csv').write(
            "o,a,b,c\n" \
            'x,1,2,3'
          )
        end

        it 'retrieves the parent balance' do
          expect(described_class.find(dataset.key).path)
            .to eq(dataset.dataset_dir.join('energy_balance.open_access.csv'))
        end
      end
    end

    describe '#get' do
      it 'returns correct value for NL when asked for a specific attribute' do
        allow(eb).to receive(:cell).and_return(6)
        expect(eb.get('Residential','coal_and_peat')).to eql 6.0
      end

      it 'works with other units' do
        eb.unit = :twh
        allow(eb).to receive(:cell).and_return(6)

        expect(eb.get('Residential','coal_and_peat')).
          to eq(EnergyUnit.new(6, :tj).to_unit(:twh))
      end

      it 'raises an error when an unknown unit is requested' do
        eb.unit = :i_do_not_exist
        allow(eb).to receive(:cell).and_return(6)
        expect(->{ eb.get('Residential','coal_and_peat') }).to \
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
