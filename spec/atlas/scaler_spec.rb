require 'spec_helper'

module Atlas; describe Scaler do
  describe "create local dataset" do
    let(:graph) { Turbine::Graph.new }

    let(:scaler) { Atlas::Scaler.new('nl', 'ameland', 1000) }

    let!(:mock_graph) {
      allow(GraphBuilder).to receive(:build).and_return(graph)
    }

    let(:local_dataset) { Atlas::LocalDataset.find('ameland') }

    before { scaler.create_scaled_dataset }

    it 'creates a file called ameland.ad' do
      expect(local_dataset).to_not be_blank
    end

    it 'has a scaling value of 1000' do
      expect(local_dataset.scaling['value']).to eq(1000)
    end

    it 'dumps a graph.yml' do
      expect(local_dataset.graph).to eq('')
    end
  end
end; end
