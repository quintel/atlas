# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::Dataset::CurveSet::Variant do
  let(:parent_path) { Pathname.new(Dir.mktmpdir) }
  let(:path) { parent_path.join('variant').tap(&:mkdir) }
  let(:variant) { described_class.new(path) }

  after { path.rmtree if path.exist? }

  before do
    path.join('c1.csv').write('1.0')
    path.join('c2.csv').write('2.0')
  end

  context 'with two curves "c1" and "c2"' do
    it 'has two curves' do
      expect(variant.length).to eq(2)
    end

    it 'has a "c1" curve' do
      expect(variant.curve?('c1')).to be(true)
    end

    it 'has a "c2" curve' do
      expect(variant.curve?('c2')).to be(true)
    end

    it 'does not have a "c3" curve' do
      expect(variant.curve?('c3')).to be(false)
    end

    it 'loads the curves' do
      allow(Atlas::Util).to(
        receive(:load_curve)
          .with(variant.curve_path('c1'))
          .and_return('1.0')
      )

      expect(variant.curve('c1')).to eq('1.0')
    end

    describe 'curve paths' do
      it 'looks for .csv files only' do
        expect(variant.curve_path('c1.csv').to_s)
          .to end_with('.csv')
      end

      it 'contains the variant directory' do
        expect(variant.curve_path('c1.csv').to_s)
          .to start_with(variant.path.to_s)
      end

      it 'removes directory traversals' do
        expect(variant.curve_path('../hi')).to eq(variant.path.join('hi.csv'))
      end
    end
  end
end
