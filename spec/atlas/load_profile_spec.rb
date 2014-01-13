require 'spec_helper'

module Atlas

  describe LoadProfile do

    let(:load_profile) do
      LoadProfile.new(
        Atlas.data_dir.join('datasets/nl/load_profiles/total_demand.yml'))
    end

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
