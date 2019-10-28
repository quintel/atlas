# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe Dataset::Derived do
    let(:dataset) do
      Dataset::Derived.new(
        key: 'lutjebroek',
        base_dataset: 'nl',
        interconnector_capacity: 1.0,
        scaling: Preset::Scaling.new(
          area_attribute: 'number_of_residences',
          value: 1000,
          base_value: 10_000
        )
      )
    end

    describe 'find by geo_id' do
      let(:dataset) { Dataset::Derived.find(:groningen) }

      it 'find by geo id' do
        expect(Dataset::Derived.find_by_geo_id('test')).to eq(dataset)
      end
    end
  end; end
