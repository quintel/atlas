# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Dataset::CurveSet do
  let(:path) { Pathname.new(Dir.mktmpdir(%w[curve set])) }
  let(:set) { described_class.new(path) }

  after { path.rmtree if path.exist? }

  context 'when initialized with a path' do
    it 'sets the curve set path' do
      expect(set.path).to eq(path)
    end

    it 'infers the name from the directory' do
      expect(set.name).to match(%r{\Acurve[^/]+set\z})
    end
  end

  context 'when the directory no children' do
    it 'has no variants' do
      expect(set.to_a).to eq([])
    end
  end

  context 'with a "variant_one" subdirectory with one "c1" CSV' do
    before do
      path.join('variant_one').mkdir
      path.join('variant_one/c1.csv').write('1.0')
    end

    it 'has one variants' do
      expect(set.to_a.length).to eq(1)
    end

    it 'has a variant called "variant_one"' do
      expect(set.variant?('variant_one')).to be(true)
    end

    it 'can provide a variant called "variant_one"' do
      expect(set.variant('variant_one')).not_to be_nil
    end

    it 'does not have a variant called "variant_two"' do
      expect(set.variant?('variant_two')).to be(false)
    end

    it 'cannot provide a variant called "variant_two"' do
      expect(set.variant('variant_two')).to be_nil
    end

    describe 'the "variant_one" variant' do
      let(:variant) { set.variant('variant_one') }

      it 'has a path' do
        expect(variant.path).to eq(path.join('variant_one'))
      end

      it 'has a single curve' do
        expect(variant.length).to eq(1)
      end

      it 'has a curve called "c1' do
        expect(variant.curve?('c1')).to be(true)
      end

      it 'does not have a curve called "c2' do
        expect(variant.curve?('c2')).to be(false)
      end
    end
  end

  context 'with a "variant_one" and "variant_two" subdirectories' do
    before do
      path.join('variant_one').mkdir
      path.join('variant_two').mkdir
    end

    it 'has two variants' do
      expect(set.to_a.length).to eq(2)
    end

    it 'has a "variant_one" variant' do
      expect(set.variant?('variant_one')).to be(true)
    end

    it 'has a "variant_two" variant' do
      expect(set.variant?('variant_two')).to be(true)
    end

    it 'does not have a "variant_three" variant' do
      expect(set.variant?('variant_three')).to be(false)
    end
  end
end
