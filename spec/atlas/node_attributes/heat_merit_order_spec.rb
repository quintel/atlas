# frozen_string_literal: true

require 'spec_helper'

describe Atlas::NodeAttributes::HeatMeritOrder do
  describe '#temperature' do
    it 'returns HT as default' do
      expect(described_class.new.temperature).to eq(:ht)
    end
  end
end
