# frozen_string_literal: true

require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe CommentBlock do
        let(:block) do
          CommentBlock.new([Line.new('# hello'), Line.new('# world!')])
        end

        describe '#key' do
          it 'parses correctly' do
            expect(block.key).to be :comment
          end
        end

        describe '#value' do
          it 'parses correctly' do
            expect(block.value).to eql "hello\nworld!"
          end
        end
      end
    end
  end
end
