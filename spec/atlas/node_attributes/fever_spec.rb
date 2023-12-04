# frozen_string_literal: true

require 'spec_helper'

describe Atlas::NodeAttributes::Fever do
  describe '#curve for consumer nodes' do
    context 'when the curve is not a hash' do
      it 'has an error' do
        mo = described_class.new(type: :consumer, curve: :households_heating)
        expect(mo.errors_on(:curve)).to include('must consist of a definition for each technology curve type, e.g. curve.tech_day_night')
      end
    end

    context 'when one curve key is not valid' do
      it 'has an error' do
        mo = described_class.new(type: :consumer, curve: {tech_nope: :households_heating })
        expect(mo.errors_on(:curve)).to include('keys must be one of [:tech_day_night, :tech_constant]')
      end
    end

    context 'when no curve is specified' do
      it 'has an error' do
        mo = described_class.new(type: :consumer)
        expect(mo.errors_on(:curve)).to include('must be set for consumers')
      end
    end
  end
end
