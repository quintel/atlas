require 'spec_helper'

module Tome
  describe Runner, :fixtures do
    let(:runner) do
      Runner.new(Dataset.find(:nl), GraphBuilder.build(:simple_graph))
    end

    it 'exposes a graph' do
      expect(runner.graph).to be_a(Turbine::Graph)
    end

    it 'exposes the Refinery graph' do
      expect(runner.refinery_graph).to be_a(Turbine::Graph)
    end

    it 'exposes a runtime' do
      expect(runner.runtime).to be_an(Tome::Runtime)
    end

    it 'provides access to the original dataset' do
      expect(runner.dataset).to be_an(Tome::Dataset)
    end

    describe '#calculate' do
      let(:edge)  { Edge.find('baz-bar@corn') }
      let(:graph) { runner.calculate }

      # The Turbine edge.
      let(:t_edge) do
        graph.node(:bar).out_edges.detect do |edge|
          edge.to.key == :baz && edge.label == :corn
        end
      end

      it 'sets demand of nodes using energy balances' do
        # This number is defined in the energy balance nl.csv file, and the
        # query is `EB(residential, natural_gas) * 1.0`.
        expect(graph.node(:fd).get(:demand)).
          to eq(Tome::EnergyUnit.new(7460.0, :tj).to_unit(:pj))
      end

      it 'sets the child share of edges using SHARE()' do
        edge.update_attributes!(sets: :child_share)

        # Extracted from the nl/shares/cars.csv file.
        expect(t_edge.get(:child_share)).to eq(0.1)
      end

      it 'sets the parent share of edges using SHARE()' do
        edge.update_attributes!(sets: :parent_share)

        # Extracted from the nl/shares/cars.csv file.
        expect(t_edge.get(:parent_share)).to eq(0.1)
      end

      context 'when a node has an output attribute' do
        it 'sets the share of slots with an efficiency' do
          Node.new(path: 'simple_graph/abc', query: 5.0,
                   output: { gas: 0.65 }).save!

          expect(graph.node(:abc).slots.out(:gas).get(:share)).to eq(0.65)
        end
      end

      it 'sets the demand of edges' do
        edge.update_attributes!(query: '5.0', sets: :demand)

        # The final demand node has a demand of 7.46, and the edge going into
        # bar has a demand of 5.0. The ratio is therefore 5/7.46 or, since
        # Rational doesn't allow you to use fractions: 500/746:

        ratio   = Rational('500/746')
        i_ratio = Rational('1') - ratio

        Node.find(:bar).update_attributes!(
          output: { corn: ratio, coal: i_ratio })

        Node.find(:fd).update_attributes!(
          input: { corn: ratio, coal: i_ratio })

        expect(t_edge.get(:demand)).to eq(5.0)
      end
    end # calculate
  end # Runner
end # Tome
