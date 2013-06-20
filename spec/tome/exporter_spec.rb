require 'spec_helper'

module Tome
  describe Exporter, :fixtures do
    before { Tome.load_library('refinery') }

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
    let!(:mother)  { graph.add Refinery::Node.new(:mother, demand: 25) }
    let!(:father)  { graph.add Refinery::Node.new(:father, demand: 10) }
    let!(:child)   { graph.add Refinery::Node.new(:child,  demand: 25) }

    # Edges
    let!(:mf_edge) { mother.connect_to(father, :spouse, child_share: 1.0) }
    let!(:mc_edge) { mother.connect_to(child,  :child,  child_share: (15.0 / 25.0)) }
    let!(:fc_edge) { father.connect_to(child,  :child,  child_share: (10.0 / 25.0)) }

    # Slots
    let!(:mf_slot) { mother.slots.out(:spouse).set(:share, 10.0 / 25.0) }
    let!(:mc_slot) { mother.slots.out(:child).set(:share, 15.0 / 25.0) }

    # Result and Output
    let!(:result) do
      Exporter.new(graph).export_to(Tome.data_dir.join('o/export.yml'))
    end

    let(:edges) do
      YAML.load_file(Tome.data_dir.join('o/export.yml'))[:edges]
    end

    let(:nodes) do
      YAML.load_file(Tome.data_dir.join('o/export.yml'))[:nodes]
    end

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
        expect(edges[:'mother-father@spouse'][:child_share]).to eq(1)
      end

      it 'writes [M]->[C] share' do
        expect(edges[:'mother-child@child'][:child_share]).to eq(15.0 / 25.0)
      end

      it 'writes [F]->[C] share' do
        expect(edges[:'father-child@child'][:child_share]).to eq(10.0 / 25.0)
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
end # Tome
