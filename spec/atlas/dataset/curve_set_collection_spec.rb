# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::Dataset::CurveSetCollection do
  context 'when initialized using at_path' do
    let(:path) { Pathname.new(Dir.mktmpdir(%w[curve set])) }
    let(:collection) { described_class.at_path(path) }

    context 'with a valid directory containing two sets' do
      before do
        path.join('first_set').mkdir
        path.join('second_set').mkdir
      end

      after { path.rmtree if path.exist? }

      it 'has two sets' do
        expect(collection.length).to eq(2)
      end

      it 'contains the first set' do
        expect(collection.key?('first_set')).to be(true)
      end

      it 'contains the second set' do
        expect(collection.key?('second_set')).to be(true)
      end
    end

    context 'with an empty directory' do
      it 'has no sets' do
        expect(collection.length).to be_zero
      end
    end

    context 'with a directory which does not exist' do
      before { path.rmtree }

      it 'raises an error' do
        expect { collection }.to raise_error(Errno::ENOENT)
      end
    end
  end

  context 'with no sets' do
    let(:collection) { described_class.new([]) }

    it 'has 0 sets' do
      expect(collection.length).to eq(0)
    end

    describe '#get!' do
      it 'raises an error' do
        expect { collection.get!('nope') }.to raise_error(
          Atlas::MissingCurveSetError,
          'No curve set called "nope" found at (unknown path)'
        )
      end
    end
  end

  context 'with sets called "set_1" and "set_2"' do
    let(:set_1) { Atlas::Dataset::CurveSet.new(Pathname.new('set_1')) }
    let(:set_2) { Atlas::Dataset::CurveSet.new(Pathname.new('set_2')) }

    let(:collection) { described_class.new([set_1, set_2]) }

    it 'has two sets' do
      expect(collection.length).to eq(2)
    end

    it 'has a set called "set_1"' do
      expect(collection.key?('set_1')).to be(true)
    end

    it 'can retrieve "set_1"' do
      expect(collection.get('set_1')).to eq(set_1)
    end

    it 'can retrieve sets with #[]' do
      expect(collection['set_1']).to eq(set_1)
    end

    it 'has a set called "set_2"' do
      expect(collection.key?('set_2')).to be(true)
    end

    it 'can retrieve "set_2"' do
      expect(collection.get('set_2')).to eq(set_2)
    end

    it 'does not have a set called "set_3"' do
      expect(collection.key?('set_3')).to be(false)
    end

    it 'returns nil when retrieving "set_3"' do
      expect(collection.get('set_3')).to be_nil
    end

    it 'can yield each set with Enumerable' do
      expect(collection.map.with_index { |s, i| [i, s] }).to eq([
        [0, set_1],
        [1, set_2]
      ])
    end

    it 'can provide a list of each sets with #to_a' do
      expect(collection.to_a).to eq([set_1, set_2])
    end

    describe '#get!' do
      it 'fetches a set which exists' do
        expect(collection.get!('set_1')).to eq(set_1)
      end

      it 'raises an error when the set does not exist' do
        expect { collection.get!('nope') }.to raise_error(
          Atlas::MissingCurveSetError,
          'No curve set called "nope" found at "."'
        )
      end
    end
  end
end
