# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Exporter::GraphExporter do
  include Atlas::GraphHelper

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
  let!(:mc_edge) { make_edge(mother, child,  :child,  child_share: (15.0 / 25.0)) }

  # Result and Output
  let(:result) { described_class.dump(graph) }
  let(:edges)  { result[Atlas::GraphConfig.energy.edge_class.name] }
  let(:nodes)  { result[Atlas::GraphConfig.energy.node_class.name] }

  # Slots and edges which aren't explicitly tested.
  before do
    make_edge(mother, father, :spouse, child_share: 1.0)
    make_edge(father, child,  :child,  child_share: (10.0 / 25.0))

    mother.slots.out(:spouse).set(:share, 10.0 / 25.0)
    mother.slots.out(:child).set(:share, 15.0 / 25.0)
  end

  # ------------------------------------------------------------------------

  it 'writes static scalar data from the document' do
    model = mother.get(:model)
    model.has_loss = false

    expect(nodes[:mother][:has_loss]).to be(false)
  end

  it 'writes static complex data from the document' do
    model = mother.get(:model)
    model.groups = %w[group_one group_two]

    expect(nodes[:mother][:groups]).to eq(model.groups)
  end

  it 'prefers data from the graph over the document' do
    mother.get(:model).demand = 100
    expect(nodes[:mother][:demand]).to eq(25.0)
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
  end

  describe 'saving when there are molecule nodes and edges' do
    let!(:molecule_from) { graph.add(make_node(:m_from, class: Atlas::MoleculeNode, demand: 25)) }
    let!(:molecule_to) { graph.add(make_node(:m_to, class: Atlas::MoleculeNode, demand: 25)) }

    let!(:molecule_edge) do
      make_edge(molecule_from, molecule_to, :co2, class: Atlas::MoleculeEdge, child_share: 1.0)
    end

    let(:molecule_nodes)  { result[Atlas::GraphConfig.molecules.node_class.name] }
    let(:molecule_edges)  { result[Atlas::GraphConfig.molecules.edge_class.name] }

    it 'writes [M_FROM] demand' do
      expect(molecule_nodes[:m_from][:demand]).to eq(molecule_from.demand)
    end

    it 'writes [M_TO] demand' do
      expect(molecule_nodes[:m_to][:demand]).to eq(molecule_to.demand)
    end

    it 'writes [M_FROM]->[M_TO] child share' do
      expect(molecule_edges[:'m_from-m_to@co2'][:child_share]).to eq(molecule_edge.child_share)
    end

    it 'does not save molecule data with energy data' do
      expect(nodes[:m_from]).to be_nil
    end

    it 'does not save energy data with molecule data' do
      expect(molecule_nodes[:mother]).to be_nil
    end
  end

  # ------------------------------------------------------------------------

  describe 'special cases' do
    it 'exports demand of contant edges' do
      mc_edge.get(:model).type = :constant
      mc_edge.set(:demand, 1337)

      expect(edges[:'mother-child@child']).to include(demand: 1337.0)
    end

    it 'exports parent_share of reversed share edges' do
      mc_edge.set(:parent_share, 0.3)

      mc_edge.get(:model).type     = :share
      mc_edge.get(:model).reversed = true

      expect(edges[:'mother-child@child']).to include(parent_share: 0.3)
    end

    it 'exports elastic slots with share=:elastic' do
      mother.get(:model).output[:loss] = :elastic
      slot = Atlas::Slot.slot_for(mother.get(:model), :out, :loss)

      mother.slots.out.add(:loss, type: :elastic, model: slot)

      expect(nodes[:mother][:output]).to include(loss: :elastic)
    end

    it 'exports merit order data as a hash' do
      mother.get(:model).merit_order =
        Atlas::NodeAttributes::ElectricityMeritOrder.new(
          type: :rock,
          group: 'The Flower Kings'
        )

      expect(nodes[:mother][:merit_order]).to eq(
        type: :rock,
        subtype: :generic,
        group: :'The Flower Kings',
        level: :hv
      )
    end

    it 'exports storage data as a hash' do
      mother.get(:model).storage =
        Atlas::NodeAttributes::Storage.new(volume: 1, decay: 0.5)

      expect(nodes[:mother][:storage]).to eq(
        volume: 1.0,
        cost_per_mwh: 0.0,
        decay: 0.5
      )
    end
  end

  describe 'max demand' do
    it 'is exported when specified in the document' do
      mother.set(:max_demand, 50)
      mother.get(:model).max_demand = 50.0

      expect(nodes[:mother][:max_demand]).to be_within(1e-13).of(50)
    end

    it 'is not exported when not specified in the document' do
      mother.set(:max_demand, 50)

      expect(nodes[:mother]).not_to have_key(:max_demand)
    end

    it 'is exported as :recursive when the original value is :recursive' do
      mother.set(:max_demand, 50)
      mother.get(:model).max_demand = :recursive

      expect(nodes[:mother][:max_demand]).to eq(:recursive)
    end

    it 'is exported as "recursive" when the original value is "recursive"' do
      mother.set(:max_demand, 50)
      mother.get(:model).max_demand = 'recursive'

      expect(nodes[:mother][:max_demand]).to eq('recursive')
    end
  end

  describe 'coupling carrier' do
    it 'is exported as an output slot share' do
      mother.set(:cc_out, 2.0)
      expect(nodes[:mother][:output][:coupling_carrier]).to eq(2)
    end

    it 'is exported as an input slot share' do
      child.set(:cc_in, 2.0)
      expect(nodes[:child][:input][:coupling_carrier]).to eq(2)
    end

    it 'is exported as an edge share' do
      key  = Atlas::Edge.key(:fd, :bar, :coupling_carrier)
      edge = Atlas::EnergyEdge.new(key: key, child_share: 1.0, type: :share)

      edge.save!

      expect(edges[key]).
        to include(share: 1.0, reversed: false, type: :share)
    end
  end

end
