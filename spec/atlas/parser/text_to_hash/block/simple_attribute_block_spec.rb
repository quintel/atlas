require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe SimpleAttributeBlock do

        let(:block) do
          SimpleAttributeBlock.new([Line.new("- unit = kg")])
        end

        describe '#key' do

          it 'parses undercases' do
            expect(block.key).to eql :unit
          end

          it 'parses numbers' do
            block = SimpleAttributeBlock.new([Line.new("- free_co2_factor = 0.0")])
            expect(block.key).to eql :free_co2_factor
          end

        end

        describe '#value' do

          it 'parses strings' do
            expect(block.value).to eql 'kg'
          end

          it 'parses floats' do
            block = SimpleAttributeBlock.new([Line.new("- foo = 12.3")])
            expect(block.value).to eql 12.3
          end

          it 'parses integers' do
            block = SimpleAttributeBlock.new([Line.new("- foo = 12")])
            expect(block.value).to eql 12
          end

          it 'parses blanks' do
            block = SimpleAttributeBlock.new([Line.new("- foo =")])
            expect(block.value).to eq('')
          end

          it 'parses single-line arrays' do
            block = SimpleAttributeBlock.new([Line.new("- groups = [a, b, c]")])
            expect(block.value).to eql %w(a b c)
          end

          it 'parses single-line arrays with mixed types' do
            block = SimpleAttributeBlock.new([Line.new("- values = [1, 2.5, text]")])
            expect(block.value).to eql [1, 2.5, 'text']
          end

          it 'parses multi-line arrays' do
            block = SimpleAttributeBlock.new([
              Line.new("- groups = ["),
              Line.new("    a, b, c"),
              Line.new("  ]")
            ])
            expect(block.value).to eql %w(a b c)
          end

          it 'parses multi-line arrays with content on first line' do
            block = SimpleAttributeBlock.new([
              Line.new("- groups = [a,"),
              Line.new("    b, c]")
            ])
            expect(block.value).to eql %w(a b c)
          end

          it 'parses multi-line arrays with mixed types' do
            block = SimpleAttributeBlock.new([
              Line.new("- values = ["),
              Line.new("    1, 2.5,"),
              Line.new("    text, 3"),
              Line.new("  ]")
            ])
            expect(block.value).to eql [1, 2.5, 'text', 3]
          end

          it 'parses multi-line arrays spanning many lines' do
            block = SimpleAttributeBlock.new([
              Line.new("- groups = ["),
              Line.new("    emissions, emissions_buildings, emissions_buildings,"),
              Line.new("    emissions_buildings_space_heating, demand_driven,"),
              Line.new("    heat_production, application_group, aggregator_producer,"),
              Line.new("    wacc_proven_tech, costs_building_and_installations_buildings,"),
              Line.new("    delivery_system_buildings"),
              Line.new("  ]")
            ])
            expect(block.value).to eql %w(
              emissions emissions_buildings emissions_buildings
              emissions_buildings_space_heating demand_driven
              heat_production application_group aggregator_producer
              wacc_proven_tech costs_building_and_installations_buildings
              delivery_system_buildings
            )
          end

        end

      end
    end
  end
end




