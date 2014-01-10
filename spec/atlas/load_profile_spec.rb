require 'spec_helper'

module Atlas

  describe LoadProfile do

    around(:each) do |example|
      Atlas.with_data_dir('spec/fixtures') { example.run }
    end

    let(:load_profile) { LoadProfile.new('total_demand.yml') }

    describe '#new' do
      it 'loads the fixtures' do
        expect(load_profile).to be_a LoadProfile
      end
    end

    describe '#values' do
      it 'is an Array' do
        expect(load_profile.values).to be_a Array
      end
      it 'contains the right values' do
        expect(load_profile.values).to eq [1,2,1.5,10]
      end
    end

  end # LoadProfile

end # ETSource
