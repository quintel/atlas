require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe Block do

        let(:block) { Block.new }
        let(:line1) { Line.new('# hello') }
        let(:line2) { Line.new('# world') }

        before { block.lines = [line1, line2] }

        describe '#new' do
          it 'registers lines immediately' do
            block = Block.new([line1, line2])
            expect(block.lines).to eql [line1, line2]
          end
        end

        describe '#lines' do
          it 'remembers' do
            expect(block.lines).to eql [line1, line2]
          end
        end

        describe '#type' do
          it 'knows the type' do
            expect(block.type).to eql :comment
          end
        end

        describe '#to_hash' do
          it 'uses key and value' do
            allow(block).to receive(:key).and_return(:foo)
            allow(block).to receive(:value).and_return('bar!')

            expect(block.to_hash).to eq({ foo: 'bar!' })
          end
        end

      end
    end
  end
end

