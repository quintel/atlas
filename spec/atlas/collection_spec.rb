require 'spec_helper'

module Atlas
  describe Collection do
    let(:node_one)   { EnergyNode.new(key: :one) }
    let(:node_two)   { EnergyNode.new(key: :two) }
    let(:node_three) { EnergyNode.new(key: :three) }
    let(:raw)        { [node_one, node_two, node_three] }
    let(:collection) { Collection.new([node_one, node_two, node_three]) }

    describe '#find' do
      it 'returns the document which matches the given key' do
        expect(collection.find(:two)).to eq(node_two)
      end

      it 'returns the document when there are similar entries' do
        collection.push(EnergyNode.new(key: :ona))
        expect(collection.find(:one)).to eq(node_one)
      end

      it 'raises an error when no document matches' do
        expect { collection.find(:nope) }.
          to raise_error(DocumentNotFoundError)
      end

      it 'raises an error when the collection is empty'
    end

    describe '#fetch' do
      it 'returns the first matching document' do
        expect(collection.fetch(:nope, :two, :one)).to eq(node_two)
      end

      it 'raises an error when no document matches' do
        expect { collection.fetch(:nope, :also_nope) }.
          to raise_error(DocumentNotFoundError)
      end
    end

    describe '#to_a' do
      it 'returns the documents as an array' do
        expect(collection.to_a).to eq(raw)
      end
    end

    describe '#each' do
      it 'delegates to the original collection' do
        elements = []
        collection.each { |v| elements.push(v) }

        expect(elements).to eq(raw)
      end
    end

    describe 'when a document key changes' do
      before { collection.find(:one) ; node_one.key = :new }

      it 'returns the document when given the old key' do
        expect(collection.find(:one)).to eq(node_one)
      end

      it 'does not return the document when given the new key' do
        expect(collection.key?(:new)).to be(false)
      end

      context 'with a refreshed collection' do
        let(:refreshed) { collection.refresh }

        it 'does not return the document when given the old key' do
          expect(refreshed.key?(:one)).to be(false)
        end

        it 'does returns the document when given the new key' do
          expect(refreshed.find(:new)).to eq(node_one)
        end
      end
    end
  end
end
