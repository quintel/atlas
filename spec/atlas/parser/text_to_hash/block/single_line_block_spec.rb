require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe SingleLineBlock do

        let(:block) do
          SingleLineBlock.new([Line.new("- unit = kg")])
        end

        describe '#key' do

          it 'parses correctly' do
            expect(block.key).to eql :unit
          end

        end

        describe '#value' do

          it 'parses correctly' do
            expect(block.value).to eql 'kg'
          end

        end

      end
    end
  end
end




