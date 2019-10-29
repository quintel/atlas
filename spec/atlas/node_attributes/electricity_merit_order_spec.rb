# frozen_string_literal: true

require 'spec_helper'

describe Atlas::NodeAttributes::ElectricityMeritOrder do
  describe '#delegate' do
    it 'returns nil' do
      expect(described_class.new.delegate).to be_nil
    end

    it 'returns a value when one is set' do
      expect(described_class.new(delegate: :hi).delegate).to eq(:hi)
    end
  end
end
