require 'spec_helper'

module Atlas
  module Parser
    describe Identifier do

      describe '#type' do

        context 'identifiable strings' do

          it 'recognizes comments' do
            expect(Identifier.type('# comment')).to eql :comment
          end

          it 'recognizes static variables' do
            expect(Identifier.type('- unit = kg')).to eql :static_variable
          end

          it 'recognizes dynamic variables' do
            expect(Identifier.type('~ demand =')).to eql :dynamic_variable
          end

          it 'recognizes inner blocks' do
            expect(Identifier.type('  SUM(1,2)')).to eql :inner_block
          end

        end

        context 'non-identifiable strings' do

          it 'raises an error' do
            expect { Identifier.type(nil) }.to raise_error CannotIdentifyError
          end

        end

      end
    end
  end
end

