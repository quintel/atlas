require 'spec_helper'

module Atlas::ActiveDocument

  describe Translator, :fixtures do

    let(:some_document) { Atlas::SomeDocument.find(:foo) }

    describe '#to_csv' do
      it 'contains unit, kg' do
        expect(some_document.to_csv).to include "unit,kg\n"
      end
    end
  end

end
