require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe SingleLineBlock do

        let(:block) do
          SingleLineBlock.new([Line.new("- unit = kg")])
        end

        describe '#key' do

          it 'parses undercases' do
            expect(block.key).to eql :unit
          end

          it 'parses numbers' do
            block = SingleLineBlock.new([Line.new("- co2_free = 0.0")])
            expect(block.key).to eql :co2_free
          end

        end

        describe '#value' do

          it 'parses strings' do
            expect(block.value).to eql 'kg'
          end

          it 'parses floats' do
            block = SingleLineBlock.new([Line.new("- foo = 12.3")])
            expect(block.value).to eql 12.3
          end

          it 'parses integers' do
            block = SingleLineBlock.new([Line.new("- foo = 12")])
            expect(block.value).to eql 12
          end

        end

      end
    end
  end
end




