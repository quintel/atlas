# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe GraphBuilder do
    describe '.build' do
      let(:graph) { described_class.build }

      it 'returns a Turbine::Graph' do
        expect(graph).to be_a(Turbine::Graph)
      end

      context 'nodes' do
        it 'are all added to the graph' do
          expect(graph.nodes.length).to eq(EnergyNode.all.length)
        end

        it 'sets the key on each node' do
          EnergyNode.all.each do |node|
            expect(graph.node(node.key).key).to eq(node.key)
          end
        end

        it 'each have a "model" property containing the AD instance' do
          EnergyNode.all.each do |node|
            expect(graph.node(node.key).get(:model)).to be
          end
        end

        it 'includes implicit slots (those defined with edges)' do
          # baz has no defined corn input, but has a connecting edge with bar
          expect(graph.node(:baz).slots.in.map(&:carrier)).to eq([:corn])
        end

        it 'includes explicit slots (those defined in the document)' do
          # fd has a loss output, but no edge
          expect(graph.node(:fd).slots.out.map(&:carrier)).to eq([:loss])
        end
      end

      context 'edges' do
        let(:foo_edges) { graph.node(:foo).out_edges.to_a }
        let(:bar_edges) { graph.node(:bar).out_edges.to_a }
        let(:baz_edges) { graph.node(:baz).out_edges.to_a }
        let(:fd_edges)  { graph.node(:fd).out_edges.to_a  }

        it 'are all established' do
          expect(foo_edges.length).to eq(1)
          expect(bar_edges.length).to eq(2)
          expect(baz_edges.length).to eq(1)
          expect(fd_edges.length).to eq(0)
        end

        it 'have the correct type' do
          expect(foo_edges.first.get(:type)).to be_nil
          expect(bar_edges.first.get(:type)).to be_nil
          expect(bar_edges.last.get(:type)).to be_nil
          expect(baz_edges.first.get(:type)).to eq(:overflow)
        end
      end
    end

    describe '.establish_edge' do
      let(:node)   { EnergyNode.new(key: :key) }
      let(:parent) { EnergyNode.new(key: :parent) }
      let(:nodes)  { Collection.new([node, parent]) }

      let!(:graph)    { Turbine::Graph.new }
      let!(:t_node)   { graph.add(Turbine::Node.new(:key, model: node)) }
      let!(:t_parent) { graph.add(Turbine::Node.new(:parent, model: parent)) }

      before do
        link_data.each do |link|
          described_class.establish_edge(link, graph)
        end
      end

      context 'with a single, share link' do
        let(:link_data) { [ EnergyEdge.new(key: 'parent-key@coal', type: :share) ] }
        let(:edge)      { t_node.in_edges.first }

        it 'adds a single incoming edge' do
          expect(t_node.in_edges.to_a.length).to eq(1)
        end

        it 'sets no edge type' do
          expect(edge.get(:type)).to be_nil
        end

        it 'sets the parent to EnergyNode(:parent)' do
          expect(edge.from).to eq(t_parent)
        end

        it 'adds an outgoing edge from the parent' do
          expect(t_parent.out_edges.to_a).to eq([edge])
        end

        it 'sets the :reversed property to false' do
          expect(edge.get(:reversed)).to be(false)
        end

        it 'sets the :model attribute' do
          model = edge.get(:model)

          expect(edge.label).to eq(model.carrier)
          expect(edge.parent.key).to eq(model.supplier)
          expect(edge.child.key).to eq(model.consumer)
        end
      end

      context 'with a reversed link' do
        let(:link_data) { [ EnergyEdge.new(key: 'parent-key@coal', type: :share, reversed: true) ] }
        let(:edge)      { t_node.in_edges.first }

        it 'adds a single incoming edge' do
          expect(t_node.in_edges.to_a.length).to eq(1)
        end

        it 'sets the :reversed property to true' do
          expect(edge.get(:reversed)).to be(true)
        end

        it 'does not set an edge type' do
          expect(edge.get(:type)).to be_nil
        end

        it 'adds an outgoing edge from the parent' do
          expect(t_parent.out_edges.to_a).to eq([edge])
        end
      end

      context 'with multiple links using different carriers' do
        let(:link_data) { [
          EnergyEdge.new(key: 'parent-key@coal', type: :share),
          EnergyEdge.new(key: 'parent-key@corn', type: :share)
        ] }

        describe 'the coal edge' do
          let(:edge) { t_node.in_edges.first }

          it 'sets the carrier (label) to coal' do
            expect(edge.label).to eq(:coal)
          end
        end

        describe 'the corn edge' do
          let(:edge) { t_node.in_edges.to_a.last }

          it 'sets the carrier (label) to corn' do
            expect(edge.label).to eq(:corn)
          end
        end
      end

      context 'with a non-existent node' do
        let(:link_data) { [] }

        it 'raises an InvalidLinkError with the parent does not exist' do
          link = EnergyEdge.new(key: 'nope-key@coal', type: :share)

          expect do
            described_class.establish_edge(link, graph)
          end.to raise_error(Atlas::DocumentNotFoundError)
        end

        it 'raises an InvalidLinkError with the child does not exist' do
          link = EnergyEdge.new(key: 'key-nope@coal', type: :share)

          expect do
            described_class.establish_edge(link, graph)
          end.to raise_error(Atlas::DocumentNotFoundError)
        end
      end

      context 'with a non-existent carrier' do
        let(:link_data) { [] }

        it 'raises an InvalidLinkCarrierError' do
          # Where iid=infinite improbability drive. Obviously. :)
          link = EnergyEdge.new(key: 'key-parent@iid', type: :share)

          expect do
            described_class.establish_edge(link, graph)
          end.to raise_error(Atlas::DocumentNotFoundError)
        end
      end
    end
  end
end
