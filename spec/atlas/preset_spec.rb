require 'spec_helper'

module Atlas
  describe Preset do
    it 'must have a title' do
      expect(described_class.new.errors_on(:title)).to include("can't be blank")
    end

    it 'must have an area_code' do
      expect(described_class.new.errors_on(:area_code)).to include("can't be blank")
    end

    it 'must have an end_year' do
      expect(described_class.new.errors_on(:end_year)).to include("can't be blank")
    end

    it 'must have user_values' do
      expect(described_class.new.errors_on(:user_values)).to include("can't be blank")
    end

    describe 'user values' do
      it 'permits inputs which exist' do
        preset = Preset.new(key: '0')
        preset.user_values = { pj_of_heat_import: 1.0 }

        preset.valid?

        expect(preset.errors[:user_values]).to eq([])
      end

      it 'does not permit inputs which do not exist' do
        preset = Preset.new(key: '0')
        preset.user_values = { invalid: 1.0 }

        preset.valid?

        expect(preset.errors[:user_values]).
          to include("contains input keys which don't exist: [:invalid]")
      end

      context 'with grouped inputs' do
        it 'ignores inputs which belong to no share group' do
          preset = Preset.new(user_values: { pj_of_heat_import: 5.0 })
          expect(preset.errors_on(:user_values).length).to eq(0)
        end

        it 'permits a sum of 99.99' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 49.99
          })

          expect(preset.errors_on(:user_values).length).to eq(0)
        end

        it 'permits a sum of 100' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.0
          })

          expect(preset.errors_on(:user_values).length).to eq(0)
        end

        it 'permits a sum of 100.01' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.01
          })

          expect(preset.errors_on(:user_values).length).to eq(0)
        end

        it 'ignores any missing inputs' do
          preset = Preset.new(user_values: { grouped_one: 100.0 })
          expect(preset.errors_on(:user_values).length).to eq(0)
        end

        it 'does not permit sums of less than 99.99' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 49.989
          })

          expect(preset.errors_on(:user_values)).
            to include("contains inputs belonging to the my_group share " \
                       "group, but the values sum to 99.989, not 100.0")
        end

        it 'does not permit sums of more than 100.01' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.011
          })

          expect(preset.errors_on(:user_values)).
            to include("contains inputs belonging to the my_group share " \
                       "group, but the values sum to 100.011, not 100.0")
        end
      end
    end

    describe 'scaling' do
      it 'may be blank' do
        preset = Preset.new(scaling: nil)
        preset.valid?

        error_keys = preset.errors.keys.select do |key|
          key.to_s.start_with?('scaling.')
        end

        expect(error_keys).to be_empty
      end

      it 'passes scaling errors through to the Preset' do
        preset = Preset.new(scaling: {})
        preset.valid?

        error_keys = preset.errors.keys.select do |key|
          key.to_s.start_with?('scaling.')
        end

        expect(error_keys).not_to be_empty
      end
    end
  end
end
