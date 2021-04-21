# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Exporter::CarrierExporter do
  let(:runtime) { Atlas::Runtime.new(Atlas::Dataset.find(:nl), nil) }
  let(:data) { described_class.dump(carrier, runtime) }

  context 'when the carrier contains only static attributes' do
    let(:carrier) do
      Atlas::Carrier.new(
        key: :fictional_carrier,
        sustainable: 0.5,
        infinite: true,
        co2_conversion_per_mj: 10.5
      )
    end

    it 'exports each attribute' do
      expect(data).to include(
        sustainable: 0.5,
        infinite: true,
        co2_conversion_per_mj: 10.5
      )
    end
  end

  context 'when the carrier contains a query' do
    let(:carrier) do
      Atlas::Carrier.new(
        key: :fictional_carrier,
        sustainable: 0.5,
        infinite: true,
        queries: {
          co2_conversion_per_mj: '10.5 * 3'
        }
      )
    end

    it 'exports each attribute' do
      expect(data).to include(
        sustainable: 0.5,
        infinite: true,
        co2_conversion_per_mj: 31.5
      )
    end
  end

  context 'when dumping multiple carriers' do
    let(:data) { described_class.dump_collection([carrier_one, carrier_two], runtime) }

    let(:carrier_one) do
      Atlas::Carrier.new(
        key: :fictional_carrier_one,
        sustainable: 0.5,
        infinite: true,
        co2_conversion_per_mj: 10.5
      )
    end

    let(:carrier_two) do
      Atlas::Carrier.new(
        key: :fictional_carrier_two,
        sustainable: 0.25,
        infinite: false,
        queries: {
          co2_conversion_per_mj: '10.5 * 3'
        }
      )
    end

    it 'creates a hash with keys for both carriers' do
      expect(data.keys).to eq(%i[fictional_carrier_one fictional_carrier_two])
    end

    it 'exports attributes for the first carrier' do
      expect(data[:fictional_carrier_one]).to include(
        sustainable: 0.5,
        infinite: true,
        co2_conversion_per_mj: 10.5
      )
    end

    it 'exports attributes for the second carrier' do
      expect(data[:fictional_carrier_two]).to include(
        sustainable: 0.25,
        infinite: false,
        co2_conversion_per_mj: 31.5
      )
    end
  end
end
