require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe Base do

        let(:base) { Base.new }

        describe '#new' do

          context 'when no content provided' do

            it 'contains no lines yet' do
              expect(base.lines).to be_empty
            end

          end

          context 'when content is provided' do

            it 'parses content' do
              content = '# a\n# b\n- unit = kg'
              base = Base.new(content)
              expect(base.lines[1].string).to eql '# a'
              expect(base.lines[2].string).to eql '# b'
              expect(base.lines[3].string).to eql '- unit = kg'
            end

          end

        end

        describe '#lines' do

          it 'can append lines' do
            line = Line.new('blah')
            expect(base.add_line(line)).to eql line
            expect(base.lines[1]).to eql line
          end

        end

        describe '#blocks' do

          it 'returns an array with blocks' do
          end

        end

      end
    end
  end
end
