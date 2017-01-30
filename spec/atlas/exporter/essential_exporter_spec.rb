require 'spec_helper'

module Atlas; describe EssentialExporter do
  let(:dataset)    { Dataset.find(:nl) }
  let(:graph)      { Runner.new(dataset).refinery_graph(:export) }
  let(:graph_dump) { EssentialExporter.dump(graph) }

  it 'exports correct demand for fd node' do
    expect(graph_dump[:nodes][:fd][:demand]).to eq(Rational(898, 1))
  end

  it 'exports correct parent share for bar-baz@corn' do
    expect(graph_dump[:edges][:'bar-baz@corn'][:parent_share]).to eq(Rational(1, 10))
  end
end; end
