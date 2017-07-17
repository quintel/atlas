require 'spec_helper'

module Atlas
  describe ValueObject do
    let(:klass) do
      Class.new do
        include ValueObject

        values do
          attribute :first, String
          attribute :second, String
        end
      end
    end

    describe '#to_hash' do
      it 'includes attributes with a value' do
        expect(klass.new(first: 'yes').to_hash).to include(first: 'yes')
      end

      it 'omits attributes without a value' do
        expect(klass.new(first: 'yes').to_hash.keys).not_to include(:second)
      end
    end
  end
end
