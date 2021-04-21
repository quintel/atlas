# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::Exporter do
  let(:runner) { Atlas::Runner.new(Atlas::Dataset.find(:nl)) }
  let(:data) { described_class.dump(runner) }

  it 'returns a Hash with keys for nodes' do
    keys = Atlas::GraphConfig.configs.map { |c| c.node_class.name }
    expect(data.keys & keys).to eq(keys)
  end

  it 'returns a Hash with keys for edges' do
    keys = Atlas::GraphConfig.configs.map { |c| c.edge_class.name }
    expect(data.keys & keys).to eq(keys)
  end

  it 'exports data for each energy node' do
    expect(data[Atlas::EnergyNode.name].keys.sort).to eq(Atlas::EnergyNode.all.map(&:key).sort)
  end

  it 'exports data for each molecule node' do
    expect(data[Atlas::MoleculeNode.name].keys.sort).to eq(Atlas::MoleculeNode.all.map(&:key).sort)
  end

  it 'exports data for each energy edge' do
    expect(data[Atlas::EnergyEdge.name].keys.sort).to eq(Atlas::EnergyEdge.all.map(&:key).sort)
  end

  it 'exports data for each molecule edge' do
    expect(data[Atlas::MoleculeEdge.name].keys.sort).to eq(Atlas::MoleculeEdge.all.map(&:key).sort)
  end

  it 'exports data for each carrier' do
    expect(data[Atlas::Carrier.name].keys.sort).to eq(Atlas::Carrier.all.map(&:key).sort)
  end
end
