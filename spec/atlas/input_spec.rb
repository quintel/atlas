# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe Input do
    describe 'priority' do
      it 'defaults to zero' do
        expect(Input.new(key: 'ohnoes').priority).to eq(0)
      end
    end

    describe 'share_group' do
      it 'may be nil' do
        input = Input.new(share_group: nil)
        expect(input.errors_on(:share_group).length).to eq(0)
      end

      it 'may have a value' do
        input = Input.new(share_group: :my_group)
        expect(input.errors_on(:share_group).length).to eq(0)
      end

      it 'coerces strings to a symbol' do
        expect(Input.new(share_group: 'my_group').share_group).to eq(:my_group)
      end

      it 'may not be a zero-length value' do
        input = Input.new(share_group: '')
        expect(input.errors_on(:share_group).length).to eq(1)
      end
    end

    describe 'query' do
      context 'when the input belongs to a share group' do
        let(:input) { Input.find(:grouped_one) }
        let(:other) { Input.find(:grouped_two) }

        it 'may be present' do
          expect(input.errors_on(:query).length).to eq(0)
        end

        it 'may be omitted if all other inputs in the group have a query' do
          input.query = nil
          expect(input.errors_on(:query).length).to eq(0)
        end

        it 'may not be omitted if any other input in the group omits a query' do
          input.query = nil
          other.query = nil

          expect(input.errors_on(:query).length).to eq(1)
          expect(other.errors_on(:query).length).to eq(1)

          expect(input.errors[:query]).to eq(["can't be blank"])
        end
      end
    end

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

        expect(group.length).to eq(2)
        expect(group).to include(Input.find(:grouped_one))
        expect(group).to include(Input.find(:grouped_two))
      end
    end
  end
end
