require 'spec_helper'

module Atlas
  describe Input do
    describe 'priority' do
      it 'defaults to zero' do
        expect(Input.new(key: 'ohnoes').priority).to eq(0)
      end
    end # priority

    describe '.by_share_group' do
      it 'returns a Hash' do
        expect(Input.by_share_group).to be_a(Hash)
      end

      it 'returns a key for each share group' do
        expect(Input.by_share_group.keys.sort)
          .to eq(Input.all.map(&:share_group).compact.uniq.sort)
      end

      it 'returns an array of each input in each share group' do
        group = Input.by_share_group[:my_group]

        expect(group).to have(2).inputs
        expect(group).to include(Input.find(:grouped_one))
        expect(group).to include(Input.find(:grouped_two))
      end
    end
  end # Input
end # ETSource
