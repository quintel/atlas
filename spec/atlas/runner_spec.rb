require 'spec_helper'

module Atlas
  describe Runner, :fixtures do
    shared_examples "runner" do |with_calculate = true|
      it 'exposes a graph' do
        expect(runner.graph).to be_a(Turbine::Graph)
      end

      it 'exposes the Refinery graph' do
        expect(runner.refinery_graph).to be_a(Turbine::Graph)
      end

      it 'exposes a runtime' do
        expect(runner.runtime).to be_an(Atlas::Runtime)
      end

      it 'provides access to the original dataset' do
        expect(runner.dataset).to be_an(Atlas::Dataset)
      end

      if with_calculate
        describe '#calculate' do
          let(:edge)  { EnergyEdge.find('bar-baz@corn') }
          let(:graph) { runner.refinery_graph }

          # The Turbine edge.
          let(:t_edge) do
            graph.node(:bar).out_edges.detect do |edge|
              edge.to.key == :baz && edge.label == :corn
            end
          end

          it 'sets demand of nodes using energy balances' do
            # This number is defined in the energy balance nl.csv file, and the
            # query is `EB(residential, natural_gas) * 1.0`.
            expect(graph.node(:fd).get(:demand)).to eq(898.0)
          end

          it 'sets the parent share of edges using SHARE()' do
            # Extracted from the nl/shares/cars.csv file.
            expect(t_edge.get(:parent_share)).to eq(0.1)
          end

          it 'sets the share of edges' do
            expect(graph.node(:bar).slots.out(:coal).get(:share)).to eq(0.5)
            expect(graph.node(:bar).slots.out(:corn).get(:share)).to eq(0.5)
          end
        end
      end
    end

    context 'for a Full' do
      let(:runner) do
        Runner.new(Dataset.find(:nl))
      end

      it_behaves_like "runner", 898

      let(:graph) { runner.refinery_graph }

      describe '#calculate' do
        let(:edge)  { EnergyEdge.find('bar-baz@corn') }
        let(:graph) { runner.refinery_graph }

        let(:t_edge) do
          graph.node(:bar).out_edges.detect do |edge|
            edge.to.key == :baz && edge.label == :corn
          end
        end

        context 'when a node has an output attribute' do
          it 'sets the share of slots with an efficiency' do
            EnergyNode.new(
              path: 'simple_graph/abc',
              queries: { demand: '5.0' },
              output: { gas: 0.65 }
            ).save!

            expect(graph.node(:abc).slots.out(:gas).get(:share)).to eq(0.65)
          end
        end

        it 'sets the demand of edges' do
          edge.queries[:demand] = '5.0'

          # The final demand node has a demand of 7.46, and the edge going into
          # bar has a demand of 5.0. The ratio is therefore 5/7.46 or, since
          # Rational doesn't allow you to use fractions: 500/746:

          ratio   = Rational('500/746')
          i_ratio = Rational('1') - ratio

          bar = EnergyNode.find(:bar)

          bar.update_attributes!(queries: bar.queries.merge({
            :'output.corn' => ratio.to_f.to_s,
            :'output.coal' => i_ratio.to_f.to_s
          }))

          EnergyNode.find(:fd).update_attributes!(
            input: { corn: ratio, coal: i_ratio })

          expect(t_edge.get(:demand)).to eq(5.0)
        end

        it 'sets the child share of edges using SHARE()' do
          edge.queries[:child_share] = edge.queries.delete(:parent_share)

          # Extracted from the nl/shares/cars.csv file.
          expect(t_edge.get(:child_share)).to eq(0.1)
        end
      end

      context 'max_demand' do
        let(:node) { EnergyNode.find(:bar) }

        it 'is set when :recursive' do
          node.queries[:max_demand] = 'recursive'
          expect(graph.node(:bar).get(:max_demand)).to eq(:recursive)
        end

        it 'is set when :infinity' do
          node.queries[:max_demand] = 'infinity'
          expect(graph.node(:bar).get(:max_demand)).to eq(Float::INFINITY)
        end

        it 'is set when numeric' do
          node.queries[:max_demand] = 'infinity'
          expect(graph.node(:bar).get(:max_demand)).to eq(Float::INFINITY)
        end

        it 'raises an error when non-numeric' do
          node.queries[:max_demand] = 'nope'
          expect { graph }.to raise_error(Atlas::NonNumericQueryError)
        end
      end
    end

    context 'for a Derived' do
      let(:runner) do
        dataset = Dataset.find(:groningen)

        Runner.new(dataset)
      end

      it_behaves_like "runner", false
    end
  end
end
