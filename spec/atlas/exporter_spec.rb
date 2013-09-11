require 'spec_helper'

module Atlas
  describe Exporter do
    def make_node(key, attributes = {})
      model = Atlas::Node.new(key: key)
      Refinery::Node.new(key, attributes.merge(model: model))
    end

    def make_edge(from, to, carrier, attributes = {})
      model = Atlas::Edge.new(key: Atlas::Edge.key(to.key, from.key, carrier))
      from.connect_to(to, carrier, attributes.merge(model: model))
    end

    #  (25) [M] -- 10 --> [F] (10)
    #         \           /
    #          \         /
    #           15     10
    #            \     /
    #             \   /
    #              v v
    #              [C] (25)
    let!(:graph)   { Turbine::Graph.new }

    # Nodes
    let!(:mother)  { graph.add(make_node(:mother, demand: 25)) }
    let!(:father)  { graph.add(make_node(:father, demand: 10)) }
    let!(:child)   { graph.add(make_node(:child,  demand: 25)) }

    # Edges
    let!(:mf_edge) { make_edge(mother, father, :spouse, child_share: 1.0) }
    let!(:mc_edge) { make_edge(mother, child,  :child,  child_share: (15.0 / 25.0)) }
    let!(:fc_edge) { make_edge(father, child,  :child,  child_share: (10.0 / 25.0)) }

    # Slots
    let!(:mf_slot) { mother.slots.out(:spouse).set(:share, 10.0 / 25.0) }
    let!(:mc_slot) { mother.slots.out(:child).set(:share, 15.0 / 25.0) }

    # Result and Output
    let!(:result) { Exporter.dump(graph) }
    let(:edges)   { result[:edges] }
    let(:nodes)   { result[:nodes] }

    # ------------------------------------------------------------------------

    describe 'saving a three-node, multiple carrier graph' do
      it 'writes [MOTHER] demand' do
        expect(nodes[:mother][:demand]).to eq(25.0)
      end

      it 'writes [FATHER] demand' do
        expect(nodes[:father][:demand]).to eq(10.0)
      end

      it 'writes [CHILD] demand' do
        expect(nodes[:child][:demand]).to eq(25.0)
      end

      it 'writes [M]->[F] share' do
        expect(edges[:'father-mother@spouse'][:child_share]).to eq(1)
      end

      it 'writes [M]->[C] share' do
        expect(edges[:'child-mother@child'][:child_share]).to eq(15.0 / 25.0)
      end

      it 'writes [F]->[C] share' do
        expect(edges[:'child-father@child'][:child_share]).to eq(10.0 / 25.0)
      end

      it 'writes [M]-@spouse share' do
        expect(nodes[:mother][:output][:spouse]).to eq(10.0 / 25.0)
      end

      it 'writes [M]-@child share' do
        expect(nodes[:mother][:output][:child]).to eq(15.0 / 25.0)
      end

      it 'writes [F]+@spouse share' do
        expect(nodes[:father][:input][:spouse]).to eq(1)
      end

      it 'writes [F]-@child share' do
        expect(nodes[:father][:output][:child]).to eq(1)
      end

      it 'writes [C]+@child share' do
        expect(nodes[:child][:input][:child]).to eq(1)
      end
    end # saving a three-node, multiple carrier graph

  end # Exporter
end # Atlas
