# frozen_string_literal: true

require 'spec_helper'

describe Atlas::Dataset::CurveSet do
  let(:path) { Pathname.new(Dir.mktmpdir(%w[curve set])) }
  let(:set) { described_class.new(Atlas::PathResolver.create(path)) }

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

    describe '#get!' do
      it 'returns a variant which exists' do
        expect(set.variant!('variant_one')).not_to be_nil
      end

      it 'raises an error when the variant does not exist' do
        expect { set.variant!('nope') }.to raise_error(
          Atlas::MissingCurveSetVariantError,
          %(No curve set variant called "nope" found at "#{path}")
        )
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

  context 'with an "a", "b", and "default" subdirectories' do
    before do
      path.join('a').mkdir
      path.join('b').mkdir
      path.join('default').mkdir
    end

    describe '#to_a' do
      let(:array) { set.to_a }

      it 'has three members' do
        expect(array.length).to eq(3)
      end

      it 'has the "default" set as the first element' do
        expect(array[0].name).to eq('default')
      end

      it 'has the "a" set as the second element' do
        expect(array[1].name).to eq('a')
      end

      it 'has the "b" set as the third element' do
        expect(array[2].name).to eq('b')
      end
    end

    it 'enumerates with "default" first' do
      names = set.map.with_index { |v, index| [index, v.name] }
      expect(names).to eq([[0, 'default'], [1, 'a'], [2, 'b']])
    end
  end

  context 'when initialized with a Atlas::PathResolver::WithFallback' do
    let(:fallback) { path.join('fallback/curve-set') }
    let(:preferred) { path.join('preferred/curve-set') }

    let(:set) { described_class.new(Atlas::PathResolver.create(preferred, fallback)) }

    before do
      fallback.mkpath
      preferred.mkpath
    end

    it 'sets the curve set path' do
      expect(set.path).to eq(Atlas::PathResolver.create(preferred, fallback))
    end

    it 'infers the name from the directory' do
      expect(set.name).to eq('curve-set')
    end

    context 'with a "variant_one" subdirectory in both paths, each with a CSV' do
      before do
        fallback.join('variant_one').mkdir
        fallback.join('variant_one/both.csv').write('1.0')
        fallback.join('variant_one/fallback.csv').write('1.0')

        preferred.join('variant_one').mkdir
        preferred.join('variant_one/both.csv').write('1.0')
        preferred.join('variant_one/preferred.csv').write('1.0')
      end

      it 'has one variant' do
        expect(set.to_a.length).to eq(1)
      end

      it 'has a variant called "variant_one"' do
        expect(set.variant?('variant_one')).to be(true)
      end

      it 'has three curves in the variant' do
        expect(set.variant('variant_one').length).to eq(3)
      end

      it 'reads curves preferentially from the preferred path' do
        expect(set.variant('variant_one').curve_path('both')).to eq(
          preferred.join('variant_one/both.csv')
        )
      end

      it 'reads curves from the fallback path' do
        expect(set.variant('variant_one').curve_path('fallback')).to eq(
          fallback.join('variant_one/fallback.csv')
        )
      end

      it 'reads curves from the preferred path' do
        expect(set.variant('variant_one').curve_path('preferred')).to eq(
          preferred.join('variant_one/preferred.csv')
        )
      end
    end
  end
end
