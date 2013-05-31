require 'spec_helper'

module Tome
  describe ShareData, :fixtures do
    describe 'when initialized' do
      context 'with a valid area and share data file' do
        let(:dataset) { Dataset.find(:nl) }
        let(:data)    { ShareData.new(dataset, :cars) }

        it 'sets the dataset' do
          expect(data.dataset).to eql(dataset)
        end

        it 'sets the data key' do
          expect(data.file_key).to eql(:cars)
        end

        it 'correctly references the file path' do
          expect(data.path.to_s).to include(Tome.root.to_s)
          expect(data.path.to_s).to include('/nl/shares/cars.csv')
        end
      end

      context 'with an invalid area' do
        let(:data) { ShareData.new(Dataset.new(key: :no), :cars) }

        it 'raises UnknownShareDataError' do
          expect { data }.to raise_error
        end

        it 'mentions the area name' do
          expect { data }.to raise_error(%r{/no/})
        end

        it 'mentions the file key' do
          expect { data }.to raise_error(%r{/cars.csv})
        end
      end

      context 'when an invalid share data file' do
        let(:data) { ShareData.new(Dataset.find(:nl), :nope) }

        it 'raises an error' do
          expect { data }.to raise_error
        end

        it 'mentions the area name' do
          expect { data }.to raise_error(%r{/nl/})
        end

        it 'mentions the file key' do
          expect { data }.to raise_error(%r{/nope.csv})
        end
      end
    end

    describe '#get' do
      let(:data) { ShareData.new(Dataset.find(:nl), :trucks) }

      context 'when the attribute exists' do
        it 'returns the attribute as a float' do
          expect(data.get(:gasoline)).to be_a(Float)
        end
      end

      context 'when the attribute does not exist' do
        it 'raises an UnknownShareAttributeError' do
          expect { data.get(:nope) }.
            to raise_error(UnknownCSVRowError)
        end
      end
    end # get
  end # ShareData
end # Tome
