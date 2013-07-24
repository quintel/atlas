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
          base.add_line line4
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

      end
    end
  end
end
