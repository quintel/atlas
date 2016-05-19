require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe MultiLineBlock do
        context 'with a correctly formatted block' do
          let(:block) do
            MultiLineBlock.new([
              Line.new("~ demand ="),
              Line.new("  SUM("),
              Line.new("    1,"),
              Line.new("    2"),
              Line.new("  )")
            ])
          end

          describe '#key' do
            it 'parses correctly' do
              expect(block.key).to eql :demand
            end
          end

          describe '#value' do
            it 'parses correctly' do
              expect(block.value).to eql "SUM(\n  1,\n  2\n)"
            end
          end
        end # with a correctly formatted block

        context 'when the value starts on the same line as the key' do
          let(:block) do
            MultiLineBlock.new([
              Line.new("~ demand = SUM("),
              Line.new("    1"),
              Line.new("  )")
            ])
          end

          it 'raises an error' do
            expect { block.key }.to raise_error(Atlas::ParserError)
          end
        end # when the value starts on the same line as the key
      end # MultilineBlock
    end
  end
end
