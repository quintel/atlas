require 'spec_helper'

module Atlas; describe GraphDeserializer do
  let(:dataset) { Dataset::DerivedDataset.find(:groningen) }

  shared_examples "graph" do
    it 'turns a graph.yml into a full Turbine::Graph' do
      expect(turbine_graph).to be_a(Turbine::Graph)
    end

    it 'gives node fd a demand of 898' do
      expect(turbine_graph.node(:fd).get(:demand)).to eq(898)
    end

    it 'sets the coal out slot of node foo share value to 1' do
      expect(turbine_graph.node(:foo).slots.out.get(:coal).get(:share)).to eq(1)
    end
  end

  describe "create a Turbine::Graph" do
    let(:graph_yaml)      { YAML.load_file(dataset.graph_path) }
    let(:turbine_graph)   { GraphDeserializer.build(graph_yaml) }

    it_behaves_like "graph"
  end

  describe "export and import a graph" do
    let(:graph)         { Runner.new(dataset, GraphBuilder.build).refinery_graph(:export) }
    let(:graph_yaml)    { EssentialExporter.dump(graph) }
    let(:turbine_graph) { GraphDeserializer.build(graph_yaml) }

    it_behaves_like "graph"
  end
end; end
