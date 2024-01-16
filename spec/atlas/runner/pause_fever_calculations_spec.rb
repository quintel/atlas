require 'spec_helper'

module Atlas
  describe Runner::PauseFeverCalculations, :fixtures do
    context 'with a graph' do
      let(:graph) { GraphBuilder.build }

      let(:paused_fever_graph) { described_class.call(graph) }

      it 'pauses the consumer node' do
        expect(paused_fever_graph.node(:fever_space_heat_consumer)).to be_wait
      end

      it 'does not calculate the consumer node' do
        expect(paused_fever_graph.node(:fever_space_heat_consumer).demand).to be_nil
      end

      it 'pauses the edges to the consumer node' do
        expect(paused_fever_graph.node(:fever_space_heat_consumer).in_edges.first).to be_wait
      end

      it 'does not pause the aggegrator node' do
        expect(paused_fever_graph.node(:fever_space_heat_producer_aggregator)).not_to be_wait
      end
    end
  end
end
