require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe LineGrouper do

        let(:lines) do 
          [ Line.new('# comment1'),
            Line.new('# comment2'),
            Line.new(''),
            Line.new('- unit = kg'),
            Line.new('- type = cool'),
            Line.new(''),
            Line.new('~ demand ='),
            Line.new('  SUM('),
            Line.new('  1,2)') ]
        end

        let(:grouper) { LineGrouper.new(lines) }
        let(:blocks)  { grouper.blocks }

        describe 'blocks' do
          it 'parses comments' do
            expect(blocks[0].type).to       eql :comment
            expect(blocks[0].lines.size).to eql 2
          end

          it 'parses static variables' do
            expect(blocks[1].type).to       eql :static_variable
            expect(blocks[1].lines.size).to eql 1
          end

          it 'parses second group of static variables' do
            expect(blocks[2].type).to       eql :static_variable
            expect(blocks[2].lines.size).to eql 1
          end

          it 'parses dynamic variables' do
            expect(blocks[3].type).to       eql :dynamic_variable
            expect(blocks[3].lines.size).to eql 3
          end
        end

      end
    end
  end
end
