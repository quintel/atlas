# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::NodeAttributes::MeritOrder do
  let(:attrs) { {} }

  describe '#delegate' do
    it 'returns nil' do
      expect(described_class.new.delegate).to be_nil
    end

    it 'returns nil, even when initialized with a value' do
      expect(described_class.new(delegate: :hi).delegate).to be_nil
    end
  end

  describe '#production_curtailment' do
    it 'returns nil' do
      expect(described_class.new.production_curtailment).to be_nil
    end
  end

  describe '#output_capacity_from_demand_of' do
    it 'is permitted when the subtype is :storage' do
      mod = described_class.new(
        output_capacity_from_demand_of: :hi,
        subtype: :storage
      )

      expect(mod.errors_on(:output_capacity_from_demand_of))
        .not_to include('must be blank when subtype is not storage')
    end

    it 'is not permitted when the subtype is not :storage' do
      mod = described_class.new(
        output_capacity_from_demand_of: :hi,
        subtype: :generic
      )

      expect(mod.errors_on(:output_capacity_from_demand_of))
        .to include('must be blank when subtype is not storage')
    end
  end

  describe '#output_capacity_from_demand_share' do
    it 'is permitted when the subtype is :storage' do
      mod = described_class.new(
        output_capacity_from_demand_share: :hi,
        subtype: :storage
      )

      expect(mod.errors_on(:output_capacity_from_demand_share))
        .not_to include('must be blank when subtype is not storage')
    end

    it 'is not permitted when the subtype is not :storage' do
      mod = described_class.new(
        output_capacity_from_demand_share: :hi,
        subtype: :generic
      )

      expect(mod.errors_on(:output_capacity_from_demand_share))
        .to include('must be blank when subtype is not storage')
    end
  end
end
