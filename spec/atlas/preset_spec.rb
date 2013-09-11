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
    end # user values
  end # Preset
end # Atlas
