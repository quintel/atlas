require 'spec_helper'

module Atlas; describe Dataset::Derived do
  describe "find by geo_id" do
    let(:dataset) { Dataset::Derived.find(:groningen) }

    it "find by geo id" do
      expect(Dataset::Derived.find_by_geo_id("test")).to eq(dataset)
    end
  end

  describe 'energy balance' do
    let(:dataset) { described_class.find(:groningen) }


    context 'when the dataset has its own energy balance' do
      it 'loads the parent dataset energy balance' do
        expect(dataset.energy_balance).to eq(dataset.parent.energy_balance)
      end
    end
  end

  describe 'primary production' do
    let(:dataset) { described_class.find(:groningen) }

    it 'loads the parent dataset primary production CSV' do
      expect(dataset.primary_production).to eq(dataset.parent.primary_production)
    end
  end
end; end
