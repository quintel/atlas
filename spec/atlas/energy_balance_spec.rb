# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe EnergyBalance do
    let(:eb) { described_class.find(:nl) }

    describe '.find' do
      it 'raises an error when key is invalid' do
        expect { described_class.find(nil) }.to raise_error(DocumentNotFoundError)
      end

      context 'when a dataset has an energy_balance.csv file' do
        it 'finds the correct energy balance' do
          eb = described_class.find(:nl)
          expect(eb.path).to eq(Dataset.find(:nl).dataset_dir.join('energy_balance.csv'))
        end
      end

      context 'when a dataset has an energy_balance.gpg file' do
        let(:dataset) { Atlas::Dataset.find(:nl) }

        before do
          content = dataset.dataset_dir.join('energy_balance.csv').read

          crypto = GPGME::Crypto.new(password: Atlas.password)
          encrypted = crypto.encrypt(
            content,
            pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK,
            symmetric: true
          ).to_s

          File.open(dataset.dataset_dir.join('energy_balance.gpg'), 'wb') { |f| f.write(encrypted) }
          dataset.dataset_dir.join('energy_balance.csv').unlink
        end

        it 'can read values from the decrypted CSV' do
          expect(described_class.find(:nl).get(:production, :coal_and_peat)).to eq(115)
        end

        it 'sets the path on the CSV' do
          expect(described_class.find(:nl).path)
            .to eq(dataset.dataset_dir.join('energy_balance.gpg'))
        end
      end

      context 'when a dataset has an energy_balance.open_access.csv file' do
        it 'finds the open access CSV' do
          ds = Atlas::Dataset.find(:nl)

          FileUtils.mv(
            ds.dataset_dir.join('energy_balance.csv'),
            ds.dataset_dir.join('energy_balance.open_access.csv')
          )

          expect(described_class.find(:nl).path)
            .to eq(ds.dataset_dir.join('energy_balance.open_access.csv'))
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

      it 'raises an error if the value is non-numeric' do
        allow(eb).to receive(:cell).and_return('x')
        expect { eb.get('Residential', 'coal_and_peat') }.to raise_error(/non-numeric/i)
      end
    end

    describe '#query' do
      it 'returns a value when asked for a specific number' do
        expect(eb.query('residential,coal_and_peat')).not_to be_nil
      end
    end
  end
end
