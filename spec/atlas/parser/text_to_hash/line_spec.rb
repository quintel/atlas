require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe Line do

        let(:base)  { Base.new }
        let(:line1) { Line.new('# comment') }
        let(:line2) { Line.new('- unit = kg') }
        let(:line3) { Line.new('~ demand =') }
        let(:line4) { Line.new('  SUM(1,2)') }

        before do
          base.add_line line1
          base.add_line line2
          base.add_line line3
        end

        describe '#number' do

          it 'is 1 for the first' do
            expect(line1.number).to eql 1
          end

          it 'is 2 for the second' do
            expect(line2.number).to eql 2
          end

          it 'is 3 for the third' do
            expect(line3.number).to eql 3
          end

        end

        describe '#pred' do

          context 'when no predecessor exists' do

            it 'returns nil' do
              expect(line1.pred).to be_nil
            end

          end

          context 'when a predecessor exists' do

            it 'returns the previous predecessor' do
              expect(line2.pred).to eql line1
            end

          end

        end

        describe '#succ' do

          context 'when no predecessor exists' do

            it 'returns nil' do
              expect(line3.succ).to be_nil
            end

          end

          context 'when a predecessor exists' do

            it 'returns the previous predecessor' do
              expect(line2.succ).to eql line3
            end

          end

        end

      end
    end
  end
end
