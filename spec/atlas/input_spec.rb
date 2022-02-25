require 'spec_helper'

module Atlas
  describe Input do
    describe 'priority' do
      it 'defaults to zero' do
        expect(described_class.new(key: 'ohnoes').priority).to eq(0)
      end
    end

    describe 'disabled_by' do
      context 'when empty' do
        it 'has no errors' do
          expect(described_class.new.errors_on(:disabled_by)).to be_empty
        end
      end

      context 'when specifying two valid inputs' do
        it 'has no errors' do
          input = described_class.new(disabled_by: %i[grouped_one grouped_two])
          expect(input.errors_on(:disabled_by)).to be_empty
        end
      end

      context 'when specifying two inputs, one of which does not exist' do
        let(:input) do
          described_class.new(disabled_by: %i[grouped_one nope])
        end

        it 'has no error for the valid input' do
          expect(input.errors_on(:disabled_by))
            .not_to include('references a input which does not exist: "grouped_one"')
        end

        it 'has an error for the missing input' do
          expect(input.errors_on(:disabled_by))
            .to include('references a input which does not exist: "nope"')
        end
      end

      context 'when specifying two inputs which do not exist' do
        let(:input) do
          described_class.new(disabled_by: %i[nope also_nope])
        end

        it 'has an error for the first missing input' do
          expect(input.errors_on(:disabled_by))
            .to include('references a input which does not exist: "nope"')
        end

        it 'has an error for the second missing input' do
          expect(input.errors_on(:disabled_by))
            .to include('references a input which does not exist: "also_nope"')
        end
      end

      # Update period validation

      context 'when the input period is "both" and the other is "before"' do
        before do
          described_class.new(key: 'other', update_period: 'before', query: 'NOOP()').save!
        end

        it 'has an error' do
          input = described_class.new(disabled_by: %i[other], update_period: 'both')

          expect(input.errors_on(:disabled_by)).to include(
            'cannot include "other" because it does not update present or future or ' \
            'both period'
          )
        end
      end

      context 'when the input period is "both" and the other is "future"' do
        before do
          described_class.new(key: 'other', update_period: 'future', query: 'NOOP()').save!
        end

        it 'has no errors' do
          input = described_class.new(disabled_by: %i[other], update_period: 'both')
          expect(input.errors_on(:disabled_by)).to be_empty
        end
      end

      context 'when the input period is "future" and the other is "future"' do
        before do
          described_class.new(key: 'other', update_period: 'future', query: 'NOOP()').save!
        end

        it 'has no errors' do
          input = described_class.new(disabled_by: %i[other], update_period: 'future')
          expect(input.errors_on(:disabled_by)).to be_empty
        end
      end

      context 'when the input period is "future" and the other is "present"' do
        before do
          described_class.new(key: 'other', update_period: 'present', query: 'NOOP()').save!
        end

        it 'has no errors' do
          input = described_class.new(disabled_by: %i[other], update_period: 'future')

          expect(input.errors_on(:disabled_by)).to include(
            'cannot include "other" because it does not update future period'
          )
        end
      end

      context 'when the input period is "future" and the other is "both"' do
        before do
          described_class.new(key: 'other', update_period: 'both', query: 'NOOP()').save!
        end

        it 'has no errors' do
          input = described_class.new(disabled_by: %i[other], update_period: 'future')

          expect(input.errors_on(:disabled_by)).to include(
            'cannot include "other" because it does not update future period'
          )
        end
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

        it 'may contain INPUT_VALUE' do
          input = Input.new(query: 'INPUT_VALUE(thing)')
          expect(input.errors_on(:query)).to be_empty
        end
      end
    end

    describe '.start_value_gql' do
      it 'may not contain INPUT_VALUE' do
        input = Input.new(start_value_gql: 'INPUT_VALUE(thing)')
        expect(input.errors_on(:start_value_gql)).to include('cannot contain INPUT_VALUE')
      end
    end

    describe '.min_value_gql' do
      it 'may not contain INPUT_VALUE' do
        input = Input.new(min_value_gql: 'INPUT_VALUE(thing)')
        expect(input.errors_on(:min_value_gql)).to include('cannot contain INPUT_VALUE')
      end
    end

    describe '.max_value_gql' do
      it 'may not contain INPUT_VALUE' do
        input = Input.new(max_value_gql: 'INPUT_VALUE(thing)')
        expect(input.errors_on(:max_value_gql)).to include('cannot contain INPUT_VALUE')
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

    describe '.min_value_gql' do
      it 'must be present if unit is "enum"' do
        input = Input.new(unit: 'enum')

        expect(input.errors_on(:min_value_gql)).to include(
          'must not be blank when the unit is "enum"'
        )
      end

      it 'is permitted when the unit is "enum"' do
        input = Input.new(unit: 'enum', min_value_gql: '1')
        expect(input.errors_on(:min_value_gql)).to be_empty
      end
    end
  end # Input
end # ETSource
