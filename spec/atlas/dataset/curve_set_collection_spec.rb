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
        expect(collection.curve_set?('first_set')).to be(true)
      end

      it 'contains the second set' do
        expect(collection.curve_set?('second_set')).to be(true)
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

  context 'with sets called "set_1" and "set_2"' do
    let(:set_1) { Atlas::Dataset::CurveSet.new(Pathname.new('set_1')) }
    let(:set_2) { Atlas::Dataset::CurveSet.new(Pathname.new('set_2')) }

    let(:collection) { described_class.new([set_1, set_2]) }

    it 'has two sets' do
      expect(collection.length).to eq(2)
    end

    it 'has a set called "set_1"' do
      expect(collection.curve_set?('set_1')).to be(true)
    end

    it 'can retrieve "set_1"' do
      expect(collection.curve_set('set_1')).to eq(set_1)
    end

    it 'has a set called "set_2"' do
      expect(collection.curve_set?('set_2')).to be(true)
    end

    it 'can retrieve "set_2"' do
      expect(collection.curve_set('set_2')).to eq(set_2)
    end

    it 'does not have a set called "set_3"' do
      expect(collection.curve_set?('set_3')).to be(false)
    end

    it 'returns nil when retrieving "set_3"' do
      expect(collection.curve_set('set_3')).to be_nil
    end
  end
end
