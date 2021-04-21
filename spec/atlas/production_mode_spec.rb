# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe ProductionMode do
    context 'with data for energy and molecule graphs' do
      let(:mode) do
        described_class.new(
          GraphConfig.energy.node_class.name => {
            foo: { demand: 50 }
          },
          GraphConfig.energy.edge_class.name => {
            'bar-fd@coal': { parent_share: 0.3 },
            'foo-bar@coal': {}
          },
          GraphConfig.molecules.node_class.name => {
            m_left: { demand: 10 },
            m_right: { demand: 10 }
          },
          GraphConfig.molecules.edge_class.name => {
            'm_left-m_right@co2': { child_share: 0.3 }
          }
        )
      end

      it 'retrieves energy nodes' do
        expect(mode.energy_nodes.length).to eq(1)
      end

      it 'uses static data for energy nodes' do
        expect(mode.energy_nodes.find(:foo).demand).to eq(50.0)
      end

      it 'retrieves energy edges' do
        expect(mode.energy_edges.length).to eq(2)
      end

      it 'uses static data for energy edges' do
        expect(mode.energy_edges.find(:'bar-fd@coal').parent_share).to eq(0.3)
      end

      it 'retrieves molecule nodes' do
        expect(mode.molecule_nodes.length).to eq(2)
      end

      it 'uses static data for molecule nodes' do
        expect(mode.molecule_nodes.find(:m_left).demand).to eq(10.0)
      end

      it 'retrieves molecule edges' do
        expect(mode.molecule_edges.length).to eq(1)
      end

      it 'uses static data for molecule edges' do
        expect(mode.molecule_edges.find('m_left-m_right@co2').child_share).to eq(0.3)
      end
    end

    context 'with data for carriers' do
      let(:mode) do
        described_class.new(
          Atlas::Carrier.name => {
            'coal': { co2_conversion_per_mj: 10.0 },
            'corn': { co2_conversion_per_mj: 50.0 }
          }
        )
      end

      it 'retrieves carriers' do
        expect(mode.carriers.length).to eq(2)
      end

      it 'uses static data for carriers' do
        expect(mode.carriers.find('coal').co2_conversion_per_mj).to eq(10.0)
      end
    end

    context 'with only energy graph data' do
      let(:mode) do
        described_class.new(
          GraphConfig.energy.node_class.name => {
            foo: { demand: 50 }
          },
          GraphConfig.energy.edge_class.name => {
            'bar-fd@coal': { parent_share: 0.3 },
            'foo-bar@coal': {}
          }
        )
      end

      it 'retrieves energy nodes' do
        expect(mode.energy_nodes.length).to eq(1)
      end

      it 'retrieves energy edges' do
        expect(mode.energy_edges.length).to eq(2)
      end

      it 'has no molecule nodes' do
        expect(mode.molecule_nodes).to be_empty
      end

      it 'has no molecule edges' do
        expect(mode.molecule_edges).to be_empty
      end
    end
  end
end
