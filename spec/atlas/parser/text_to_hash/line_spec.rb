# frozen_string_literal: true

require 'spec_helper'

module Atlas
  module Parser
    module TextToHash
      describe Line do
        describe '#to_s' do
          it 'is the same as string' do
            line = Line.new('bleh!')
            expect(line.to_s).to eql 'bleh!'
          end
        end
      end
    end
  end
end
