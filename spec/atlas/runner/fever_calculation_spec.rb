require 'spec_helper'

module Atlas
  describe Runner::FeverCalculation, :fixtures do
    let(:catalyst) { described_class.with_dataset(dataset) }

    let(:runner) { Atlas::Runner.new(dataset) }
    let(:dataset) { Dataset.find(:nl) }
    let(:graph) do
      refinery_graph = runner.refinery_graph
      [Refinery::Catalyst::Calculators].compact.reduce(refinery_graph) do |result, catalyst|
        catalyst.call(result)
      end
    end

    context 'with a graph with calculated fever shares' do
      let(:fever_calculated_graph) { catalyst.call(graph) }

      it 'unpauses the consumer node' do
        expect(fever_calculated_graph.node(:fever_space_heat_consumer)).not_to be_wait
      end

      it 'did not calculate the consumer node' do
        expect(fever_calculated_graph.node(:fever_space_heat_consumer).demand).to be_nil
      end

      it 'unpauses the edges to the consumer node' do
        expect(fever_calculated_graph.node(:fever_space_heat_consumer).in_edges.first).not_to be_wait
      end
    end

    context 'with a graph with refinery run again' do
      # space heating: total = 87,5 on agg
      # hot water: total = 100
      let(:fever_calculated_graph) do
        calc_graph = catalyst.call(graph)
        Refinery::Catalyst::Calculators.call(calc_graph)
      end

      it 'did calculate the consumer node' do
        expect(
          fever_calculated_graph
          .node(:fever_space_heat_consumer)
          .demand
        ).to eq(Rational(87.5 / 2))
      end

      it 'serves the first consumer in the order fully by the first producer (energy)' do
        expect(
          fever_calculated_graph
            .node(:fever_space_heat_second_consumer)
            .in_edges
            .first
            .demand
        ).to eq(Rational(87.5 / 2))
      end

      it 'serves the first consumer in the order fully by the first producer (key)' do
        expect(
          fever_calculated_graph
            .node(:fever_space_heat_second_consumer)
            .in_edges
            .first
            .from
            .key
        ).to eq(:fever_space_heat_producer_aggregator)
      end

      it 'did calculate the second consumer node' do
        expect(
          fever_calculated_graph
          .node(:fever_space_heat_second_consumer)
          .demand
        ).to eq(Rational(87.5 / 2))
      end
    end
  end
end
