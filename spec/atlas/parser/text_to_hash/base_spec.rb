require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe Base do

        let(:base)    { Base.new }
        let(:content) { "# a\n# b\n- unit = kg\n~ demand =\n  SUM(1,2)" }

        describe '#new' do

          context 'when no content provided' do

            it 'contains no lines yet' do
              expect(base.lines).to be_empty
            end

          end

          context 'when content is provided' do

            it 'parses content' do
              base = Base.new(content)
              expect(base.lines[0].to_s).to eql '# a'
              expect(base.lines[1].to_s).to eql '# b'
              expect(base.lines[2].to_s).to eql '- unit = kg'
            end

          end

        end

        describe '#lines' do

          it 'can append lines' do
            line = Line.new('blah')
            expect(base.add_line(line)).to eql line
            expect(base.lines[0]).to eql line
          end

        end

        describe '#blocks' do

          it 'has content' do
            base = Base.new(content)
            expect(base.blocks).to have(3).blocks
          end
        end

        describe '#to_hash' do

          it 'has everything' do
            base = Base.new(content)
            expect(base.to_hash).to eql({ comment: "a\nb",
                                          unit:    'kg',
                                          demand:  'SUM(1,2)' })
          end

        end

      end
    end
  end
end
