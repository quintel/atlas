# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe ProductionMode do
    let(:mode) do
      described_class.new(
        nodes: { foo: { demand: 50 } },
        edges: {
          'bar-fd@coal': { parent_share: 0.3 },
          'foo-bar@coal': {}
        }
      )
    end

    it 'retrieves nodes' do
      expect(mode.nodes.length).to eq(1)
    end

    it 'uses static data for nodes' do
      expect(mode.nodes.find(:foo).demand).to eq(50.0)
    end

    it 'retrieves edges' do
      expect(mode.edges.length).to eq(2)
    end

    it 'uses static data for edges' do
      expect(mode.edges.find(:'bar-fd@coal').parent_share).to eq(0.3)
    end
  end
end
