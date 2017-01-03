require 'spec_helper'

module Atlas; describe GraphFromYaml do
  let(:derived_dataset) { Dataset::DerivedDataset.find(:groningen) }
  let(:graph_yaml) { YAML.load_file(derived_dataset.graph_path) }
  let(:turbine_graph) { GraphFromYaml.build(graph_yaml) }

  it 'turns a graph.yml into a full Turbine::Graph' do
    expect(turbine_graph).to be_a(Turbine::Graph)
  end

  it 'gives node fd a demand of 898' do
    expect(turbine_graph.node(:fd).get(:demand)).to eq(898)
  end

  it 'sets the coal out slot of node foo share value to 1' do
    expect(turbine_graph.node(:foo).slots.out.get(:coal).get(:share)).to eq(1)
  end
end; end
