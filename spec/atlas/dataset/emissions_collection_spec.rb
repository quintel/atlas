# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::Dataset::EmissionsCollection do
  let(:fixtures_path) { Atlas.data_dir.join('datasets', 'nl', 'emissions') }

  context 'when initialized using at_path' do
    let(:collection) { described_class.at_path(fixtures_path) }

    it 'loads the default emissions' do
      expect(collection.get(:default)).to be_a(Atlas::CSVDocument::EmissionsDocument)
    end

    it 'loads historical year emissions' do
      expect(collection.get(:'1990')).to be_a(Atlas::CSVDocument::EmissionsDocument)
    end

    it 'includes default in years list' do
      expect(collection.years).to include(:default)
    end

    it 'includes 1990 in years list' do
      expect(collection.years).to include(:'1990')
    end

    it 'returns nil for non-existent year' do
      expect(collection.get(:'2000')).to be_nil
    end

    describe '#default' do
      it 'returns the default emissions document' do
        expect(collection.default).to eq(collection.get(:default))
      end
    end

    describe '#to_hash' do
      let(:hash) { collection.to_hash }

      it 'returns a hash grouped by year' do
        expect(hash).to be_a(Hash)
        expect(hash.keys).to include(:default, :'1990')
      end

      it 'contains emissions data for default year' do
        expect(hash[:default]).to be_a(Hash)
        expect(hash[:default][:households_energetic_co2]).to eq(12.0)
      end

      it 'contains emissions data for 1990' do
        expect(hash[:'1990']).to be_a(Hash)
        expect(hash[:'1990'][:energy_electricity_and_heat_production_energetic_co2]).to eq(18.0)
      end
    end

    describe '#get!' do
      it 'returns the document when it exists' do
        expect(collection.get!(:default)).to be_a(Atlas::CSVDocument::EmissionsDocument)
      end

      it 'raises an error when the year does not exist' do
        expect { collection.get!(:'2000') }.to raise_error(
          Atlas::MissingEmissionsYearError,
          /No emissions data for year :"2000"/
        )
      end

      it 'includes available years in error message' do
        expect { collection.get!(:'2000') }.to raise_error(
          Atlas::MissingEmissionsYearError,
          /Available years.*:default.*:"1990"/
        )
      end
    end
  end

  context 'with a temporary emissions directory' do
    let(:temp_dir) { Pathname.new(Dir.mktmpdir('emissions')) }
    let(:collection) { described_class.at_path(temp_dir) }

    after { temp_dir.rmtree if temp_dir.exist? }

    context 'with only default emissions' do
      before do
        temp_dir.join('emissions_default.csv').write(<<~CSV)
          etm_sector,etm_subsector,type,ghg,unit,value
          Households,,energetic,co2,kg,10.0
        CSV
      end

      it 'has one year' do
        expect(collection.years.length).to eq(1)
      end

      it 'has default year' do
        expect(collection.years).to eq([:default])
      end

      it 'can access default emissions' do
        expect(collection.default.get(:households_energetic_co2)).to eq(10.0)
      end
    end

    context 'with multiple historical years' do
      before do
        temp_dir.join('emissions_default.csv').write(<<~CSV)
          etm_sector,etm_subsector,type,ghg,unit,value
          Households,,energetic,co2,kg,10.0
        CSV

        temp_dir.join('emissions_1990.csv').write(<<~CSV)
          etm_sector,etm_subsector,type,ghg,unit,value
          Households,,energetic,co2,kg,8.0
        CSV

        temp_dir.join('emissions_2000.csv').write(<<~CSV)
          etm_sector,etm_subsector,type,ghg,unit,value
          Households,,energetic,co2,kg,9.0
        CSV
      end

      it 'has three years' do
        expect(collection.years.length).to eq(3)
      end

      it 'includes all years' do
        expect(collection.years).to match_array([:default, :'1990', :'2000'])
      end

      it 'can access each year independently' do
        expect(collection.get(:default).get(:households_energetic_co2)).to eq(10.0)
        expect(collection.get(:'1990').get(:households_energetic_co2)).to eq(8.0)
        expect(collection.get(:'2000').get(:households_energetic_co2)).to eq(9.0)
      end
    end

    context 'with an empty directory' do
      it 'has no years' do
        expect(collection.years).to be_empty
      end

      it 'returns nil for default' do
        expect(collection.get(:default)).to be_nil
      end
    end
  end
end
