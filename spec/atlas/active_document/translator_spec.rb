require 'spec_helper'

module Atlas::ActiveDocument

  describe Translator, :fixtures do

    let(:some_document) { Atlas::SomeDocument.find(:foo) }

    describe '#to_csv' do
      it 'returns the attributes' do
        expect(some_document.to_csv).to include 'unit,kg'
      end
    end
  end

end
