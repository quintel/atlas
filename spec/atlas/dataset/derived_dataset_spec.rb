# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Dataset::Derived do
  describe 'find by geo_id' do
    let(:dataset) { described_class.find(:groningen) }

    it 'returns the dataset' do
      expect(described_class.find_by_geo_id('test')).to eq(dataset)
    end
  end

  describe 'primary production' do
    let(:dataset) { described_class.find(:groningen) }

    it 'loads the parent dataset primary production CSV' do
      expect(dataset.primary_production.path).to eq(dataset.parent.primary_production.path)
    end
  end

  describe ' energy balance' do
    let(:grandchild_dataset) { described_class.find(:winschoten) }
    let(:dataset) { described_class.find(:groningen) }

    context 'when the dataset has its own energy balance' do
      it 'loads the parent dataset energy balance' do
        expect(grandchild_dataset.energy_balance).to eq(grandchild_dataset.parent.energy_balance)
      end
    end
  end

  describe 'full ancestor validation' do
    let(:dataset) { described_class.find(:groningen) }

    context 'when the dataset has a full ancestor' do
      before do
        allow(dataset).to receive(:graph_values).and_return(double(valid?: true, errors: {}))
      end

      it 'is valid' do
        expect(dataset).to be_valid
      end
    end

    context 'when Dataset::Full.exists? returns false and no parent has a full ancestor' do
      before do
        allow(Atlas::Dataset::Full).to receive(:exists?).and_return(false)
        allow(dataset.parent).to receive(:has_full_parent?).and_return(false)
        allow(dataset).to receive(:graph_values).and_return(double(valid?: true, errors: {}))
      end

      it 'is not valid' do
        expect(dataset).not_to be_valid
        expect(dataset.errors_on(:base_dataset))
          .to include('has no Full parent')
      end
    end

    context 'when Dataset::Full.exists? returns false but the parent has a full ancestor' do
      before do
        allow(Atlas::Dataset::Full).to receive(:exists?).and_return(false)
        allow(dataset.parent).to receive(:has_full_parent?).and_return(true)
        allow(dataset).to receive(:graph_values).and_return(double(valid?: true, errors: {}))
      end

      it 'is still valid' do
        expect(dataset).to be_valid
      end
    end
  end
end
