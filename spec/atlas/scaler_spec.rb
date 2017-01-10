require 'spec_helper'

module Atlas; describe Scaler do
  include GraphHelper

  # Graph:
  # [ a (25) ]--< a_b (10) >--[ b (10) ]

  let(:graph) do
    Turbine::Graph.new.tap do |graph|
      a = graph.add(make_node(:a, demand: 25))
      b = graph.add(make_node(:b, demand: 10))
      make_edge(a, b, :a_b, child_share: 1.0, demand: 10)
    end
  end

  let(:scaling_factor) { 1000.to_r / 7_349_500 }

  before { allow(GraphBuilder).to receive(:build).and_return(graph) }


  describe '#create_scaled_dataset' do
    let(:derived_dataset) { Atlas::Dataset::DerivedDataset.find('ameland') }

    context 'with scaling value 1000' do
      let(:scaler) { Scaler.new('nl', 'ameland', 1000) }

      before { scaler.create_scaled_dataset }

      it 'creates a valid DerivedDataset' do
        derived_dataset.valid?

        expect(derived_dataset.errors).to be_empty
      end

      it 'assigns a new id to the DerivedDataset' do
        datasets = Atlas::Dataset.all
        old_max = (datasets - [derived_dataset]).map(&:id).max
        expect(derived_dataset.id).to be > old_max
      end

      it 'assigns the new id also as parent_id' do
        expect(derived_dataset.parent_id).to eq(derived_dataset.id)
      end

      it 'sets the scaling value of the DerivedDataset to 1000' do
        expect(derived_dataset.scaling[:value]).to eq(1000)
      end

      it 'sets the scaling base_value of the DerivedDataset to the number_of_residences in nl' do
        expect(derived_dataset.scaling[:base_value]).
          to eq(Atlas::Dataset.find('nl').number_of_residences)
      end

      it 'assigns the correctly scaled number of residences' do
        expect(derived_dataset.number_of_residences).to eq(1000)
      end

      it 'assigns the correctly scaled number of inhabitants' do
        expect(derived_dataset.number_of_inhabitants).to be_within(0.001).of(2249.185)
      end

      it 'dumps a graph.yml' do
        expect(derived_dataset.graph).to_not be_blank
      end
    end

    context 'with scaling value nil' do
      let(:scaler) { Scaler.new('nl', 'ameland', nil) }

      it 'creates an invalid DerivedDataset' do
        expect { scaler.create_scaled_dataset }.
          to raise_error(Atlas::InvalidDocumentError, /Scaling Value/)
      end
    end
  end # create_scaled_dataset


  describe Scaler::GraphScaler do
    let(:graph_data) { EssentialExporter.dump(graph) }

    before { Scaler::GraphScaler.new(scaling_factor).call(graph_data) }

    it 'exports the correct demand 25 * scaling_factor for node :a' do
      expect(graph_data[:nodes][:a][:demand]).
        to eql(25.to_r * scaling_factor)
    end

    it 'exports the correct demand 10 * scaling_factor for edge :a->:b' do
      expect(graph_data[:edges][:'a-b@a_b'][:demand]).
        to eql(10.to_r * scaling_factor)
    end
  end # GraphScaler
end; end # Atlas::Scaler
