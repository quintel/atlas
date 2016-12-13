require 'spec_helper'

module Atlas; describe Scaler do
  describe '#create_scaled_dataset' do
    include GraphHelper

    # Graph:
    # [ a (25) ] === [ a_b (10) ] === [ b (10) ]

    let(:graph) { Turbine::Graph.new }

    let!(:a)  { graph.add(make_node(:a, demand: 25)) }
    let!(:b)  { graph.add(make_node(:b, demand: 10)) }

    let!(:ab_edge) { make_edge(a, b, :a_b, child_share: 1.0) }


    let!(:mock_graph) {
      allow(GraphBuilder).to receive(:build).and_return(graph)
    }

    let(:derived_dataset) { Atlas::Dataset::DerivedDataset.find('ameland') }

    context 'with scaling value 1000' do
      let(:scaler) { Atlas::Scaler.new('nl', 'ameland', 1000) }

      before { scaler.create_scaled_dataset }

      it 'creates a valid DerivedDataset' do
        derived_dataset.valid?

        expect(derived_dataset.errors).to be_empty
      end

      it 'sets the scaling value of the DerivedDataset to 1000' do
        expect(derived_dataset.scaling[:value]).to eq(1000)
      end

      it 'sets the scaling base_value of the DerivedDataset to the number_of_residences in nl' do
        expect(derived_dataset.scaling[:base_value]).
          to eq(Atlas::Dataset.find('nl').number_of_residences)
      end

      it 'assigns the correct number of residences' do
        expect(derived_dataset.number_of_residences).to eq(1000)
      end

      it 'dumps a graph.yml' do
        expect(derived_dataset.graph).to_not be_blank
      end

      it 'exports the correct demand 25/1 for node :a' do
        expect(derived_dataset.graph[:nodes][:a][:demand]).to eq(25/1)
      end
    end

    context 'with scaling value nil' do
      let(:scaler) { Atlas::Scaler.new('nl', 'ameland', nil) }

      it 'creates an invalid DerivedDataset' do
        expect { scaler.create_scaled_dataset }.
          to raise_error(Atlas::InvalidDocumentError, /Scaling Value/)
      end
    end
  end
end; end
