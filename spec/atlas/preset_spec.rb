require 'spec_helper'

module Atlas
  describe Preset do
    it { expect(Preset.new(key: 'o')).to validate_presence_of(:title) }
    it { expect(Preset.new(key: 'o')).to validate_presence_of(:area_code) }
    it { expect(Preset.new(key: 'o')).to validate_presence_of(:end_year) }
    it { expect(Preset.new(key: 'o')).to validate_presence_of(:user_values) }

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
          expect(preset).to have(:no).errors_on(:user_values)
        end

        it 'permits a sum of 99.99' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 49.99
          })

          expect(preset).to have(:no).errors_on(:user_values)
        end

        it 'permits a sum of 100' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.0
          })

          expect(preset).to have(:no).errors_on(:user_values)
        end

        it 'permits a sum of 100.01' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.01
          })

          expect(preset).to have(:no).errors_on(:user_values)
        end

        it 'ignores any missing inputs' do
          preset = Preset.new(user_values: { grouped_one: 100.0 })
          expect(preset).to have(:no).errors_on(:user_values)
        end

        it 'does not permit sums of less than 99.99' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 49.989
          })

          expect(preset).to have(1).error_on(:user_values)

          expect(preset.errors[:user_values]).
            to include("contains inputs belonging to the my_group share " \
                       "group, but the values sum to 99.989, not 100")
        end

        it 'does not permit sums of more than 100.01' do
          preset = Preset.new(user_values: {
            grouped_one: 50.0, grouped_two: 50.011
          })

          expect(preset).to have(1).error_on(:user_values)

          expect(preset.errors[:user_values]).
            to include("contains inputs belonging to the my_group share " \
                       "group, but the values sum to 100.011, not 100")
        end
      end
    end # user values

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
  end # Preset
end # Atlas
