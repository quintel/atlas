require 'spec_helper'

module Tome
  describe GraphBuilder, :fixtures do
    describe '.build' do
      let(:graph) { GraphBuilder.build }

      it 'returns a Turbine::Graph' do
        expect(graph).to be_a(Turbine::Graph)
      end

      context 'nodes' do
        it 'are all added to the graph' do
          expect(graph).to have(Node.all.length).nodes
        end

        it 'sets the key on each node' do
          Node.all.each do |node|
            expect(graph.node(node.key).key).to eql(node.key)
          end
        end

        it 'each have a "model" property containing the AD instance' do
          Node.all.each do |node|
            expect(graph.node(node.key).get(:model)).to be
          end
        end
      end # nodes

      context 'edges' do
        let(:foo_edges) { graph.node(:foo).out_edges.to_a }
        let(:bar_edges) { graph.node(:bar).out_edges.to_a }
        let(:baz_edges) { graph.node(:baz).out_edges.to_a }
        let(:fd_edges)  { graph.node(:fd).out_edges.to_a  }

        it 'are all established' do
          expect(foo_edges).to have(1).edge
          expect(bar_edges).to have(2).edges
          expect(baz_edges).to have(1).edge
          expect(fd_edges).to have(:no).edges
        end

        it 'have the correct type' do
          expect(foo_edges.first.get(:type)).to be_nil
          expect(bar_edges.first.get(:type)).to be_nil
          expect(bar_edges.last.get(:type)).to be_nil
          expect(baz_edges.first.get(:type)).to eql(:overflow)
        end
      end # edges

      context 'with a sector' do
        before do
          nodes = Collection.new(Node.all)
          edges = Collection.new(Edge.all)

          # Set foo and bar to be in "one".
          nodes.find(:foo).update_attributes!(sector: 'one')
          nodes.find(:bar).update_attributes!(sector: 'one')

          edges.find('bar-foo@coal').update_attributes!(ns: 'one')
          edges.find('baz-bar@corn').update_attributes!(ns: 'one')
          edges.find('fd-bar@coal').update_attributes!(ns: 'one')

          # Set baz and fd to be in "two".
          nodes.find(:baz).update_attributes!(sector: 'two')
          nodes.find(:fd).update_attributes!(sector: 'two')

          edges.find('fd-baz@corn').update_attributes!(ns: 'two')
        end

        let(:graph) { GraphBuilder.build('one') }

        it 'includes nodes in the sector' do
          expect(graph.node(:foo)).to be
          expect(graph.node(:bar)).to be
        end

        it 'excludes nodes not in the sector' do
          expect(graph.node(:baz)).to_not be
          expect(graph.node(:fd)).to_not be
        end

        it 'includes edges in the sector' do
          expect(graph.node(:foo).out_edges.to_a.length).to eql(1)
        end

        it 'includes subgraph bridge edges - to the super sink' do
          expect(graph.node(:bar).out_edges.to_a).to_not be_empty
          expect(graph.node(:bar).out.first.key).to eql(:SUPER_SINK)
        end

        it 'does not includes nodes which have no sector' do
          Node.new(key: 'abc').save!
          expect(graph.node(:abc)).to_not be
        end
      end # with a sector
    end # .build

    describe '.establish_edge' do
      let(:node)   { Node.new(key: :key) }
      let(:parent) { Node.new(key: :parent) }
      let(:nodes)  { Collection.new([node, parent]) }

      let!(:graph)    { Turbine::Graph.new }
      let!(:t_node)   { graph.add(Turbine::Node.new(:key, model: node)) }
      let!(:t_parent) { graph.add(Turbine::Node.new(:parent, model: parent)) }

      before do
        link_data.each do |link|
          GraphBuilder.establish_edge(link, graph, nodes)
        end
      end

      context 'with a single, share link' do
        let(:link_data) { [ Edge.new(key: 'key-parent@coal', type: :share) ] }
        let(:edge)      { t_node.in_edges.first }

        it 'adds a single incoming edge' do
          expect(t_node.in_edges.to_a).to have(1).edge
        end

        it 'sets no edge type' do
          expect(edge.get(:type)).to be_nil
        end

        it 'sets the parent to Node(:parent)' do
          expect(edge.from).to eql(t_parent)
        end

        it 'adds an outgoing edge from the parent' do
          expect(t_parent.out_edges.to_a).to eql([edge])
        end

        it 'sets the :reversed property to false' do
          expect(edge.get(:reversed)).to be_false
        end

        it 'sets the :model attribute' do
          model = edge.get(:model)

          expect(edge.label).to eq(model.carrier)
          expect(edge.parent.key).to eq(model.supplier)
          expect(edge.child.key).to eq(model.consumer)
        end
      end # with a single, share link

      context 'with a reversed link' do
        let(:link_data) { [ Edge.new(key: 'key-parent@coal', type: :share, reversed: true) ] }
        let(:edge)      { t_node.in_edges.first }

        it 'adds a single incoming edge' do
          expect(t_node.in_edges.to_a).to have(1).edge
        end

        it 'sets the :reversed property to true' do
          expect(edge.get(:reversed)).to be_true
        end

        it 'does not set an edge type' do
          expect(edge.get(:type)).to be_nil
        end

        it 'adds an outgoing edge from the parent' do
          expect(t_parent.out_edges.to_a).to eql([edge])
        end
      end # with a reversed link

      context 'with multiple links using different carriers' do
        let(:link_data) { [
          Edge.new(key: 'key-parent@coal', type: :share),
          Edge.new(key: 'key-parent@corn', type: :share),
        ] }

        describe 'the coal edge' do
          let(:edge) { t_node.in_edges.first }

          it 'sets the carrier (label) to coal' do
            expect(edge.label).to eql(:coal)
          end
        end # the coal edge

        describe 'the corn edge' do
          let(:edge) { t_node.in_edges.to_a.last }

          it 'sets the carrier (label) to corn' do
            expect(edge.label).to eql(:corn)
          end
        end # the corn edge
      end # with multiple links using different carriers

      context 'with a non-existent node' do
        let(:link_data) { [] }

        it 'raises an InvalidLinkError' do
          link = Edge.new(key: 'key-nope@coal', type: :share)

          expect do
            GraphBuilder.establish_edge(link, graph, nodes)
          end.to raise_error(Tome::DocumentNotFoundError)
        end
      end # with an invalid link type

      context 'with a non-existent carrier' do
        let(:link_data) { [] }

        it 'raises an InvalidLinkCarrierError' do
          # Where iid=infinite improbability drive. Obviously. :)
          link = Edge.new(key: 'key-parent@iid', type: :share)

          expect do
            GraphBuilder.establish_edge(link, graph, nodes)
          end.to raise_error(Tome::DocumentNotFoundError)
        end
      end # with a non-existent carrier
    end # .establish_edge
  end # GraphBuilder
end # Tome
