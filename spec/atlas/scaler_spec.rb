require 'spec_helper'

module Atlas; describe Scaler do
  describe "create derived dataset" do
    include GraphHelper

    # Graph:
    # [ a (25) ] === [ a_b (10) ] === [ b (10) ]

    let(:graph) { Turbine::Graph.new }

    let!(:a)  { graph.add(make_node(:a, demand: 25)) }
    let!(:b)  { graph.add(make_node(:b, demand: 10)) }

    let!(:ab_edge) { make_edge(a, b, :a_b, child_share: 1.0) }

    let(:scaler) { Atlas::Scaler.new('nl', 'ameland', 1000) }

    let!(:mock_graph) {
      allow(GraphBuilder).to receive(:build).and_return(graph)
    }

    let(:derived_dataset) { Atlas::Dataset::DerivedDataset.find('ameland') }

    before { scaler.create_scaled_dataset }

    it 'creates a file called ameland.ad' do
      expect(derived_dataset).to_not be_blank
    end

    it 'has a scaling value of 1000' do
      expect(derived_dataset.scaling[:value]).to eq(1000)
    end

    it 'dumps a graph.yml' do
      expect(derived_dataset.graph).to eq({
        :nodes => {
          :a => { :demand => (25/1), :in => {}, :out => { :a_b => {} } },
          :b => { :demand => (10/1), :in => { :a_b => {} }, :out => {} }
        },
        :edges => {
          :"a-b@a_b" => { :child_share => (1/1) }
        }
      })
    end
  end
end; end
