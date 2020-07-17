# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::NodeAttributes::EnergyToMolecules do
  context 'when "source" is blank' do
    let(:conv) { described_class.new }

    it 'has an error on "source"' do
      expect(conv.errors_on(:source)).to include('must contain a reference to a energy node')
    end
  end

  context 'when "source" references a non-existant energy node' do
    let(:conv) { described_class.new(source: :invalid) }

    it 'has an error on "source"' do
      expect(conv.errors_on(:source)).to include('references a energy node which does not exist')
    end
  end

  context 'when "source" references an energy node' do
    let(:conv) { described_class.new(source: :bar) }

    it 'has no errors on "source"' do
      expect(conv.errors_on(:source)).to be_blank
    end
  end

  context 'when "direction" is "input"' do
    let(:conv) { described_class.new(direction: :input) }

    it 'has no errors on "direction"' do
      expect(conv.errors_on(:direction)).to be_empty
    end

    it 'must have a conversion' do
      expect(conv.errors_on(:conversion))
        .to include("can't be blank when direction is one of: input, output")
    end

    it 'must have a hash conversion' do
      with_numeric_conv = described_class.new(direction: :input, conversion: 1.0)

      expect(with_numeric_conv.errors_on(:conversion))
        .to include('must name each carrier when direction is input')
    end
  end

  context 'when "direction" is "output"' do
    let(:conv) { described_class.new(direction: :output) }

    it 'has no errors on "direction"' do
      expect(conv.errors_on(:direction)).to be_empty
    end

    it 'must have a conversion' do
      expect(conv.errors_on(:conversion))
        .to include("can't be blank when direction is one of: input, output")
    end

    it 'must have a hash conversion' do
      with_numeric_conv = described_class.new(direction: :output, conversion: 1.0)

      expect(with_numeric_conv.errors_on(:conversion))
        .to include('must name each carrier when direction is output')
    end
  end

  context 'when "direction" is blank' do
    let(:conv) { described_class.new(direction: nil) }

    it 'has no errors on "direction"' do
      expect(conv.errors_on(:direction)).to be_empty
    end

    it 'may have a numeric conversion' do
      with_numeric_conv = described_class.new(conversion: 1.0)

      expect(with_numeric_conv.errors_on(:conversion)).to be_empty
    end

    it 'must not have a hash conversion' do
      with_numeric_conv = described_class.new(conversion: { a: 1.0 })

      expect(with_numeric_conv.errors_on(:conversion))
        .to include('must be numeric when direction has no value')
    end
  end

  describe '#conversion_of' do
    context 'when conversion is nil' do
      let(:conv) { described_class.new(conversion: nil) }

      it 'returns 1.0' do
        expect(conv.conversion_of(nil)).to be(1.0)
      end
    end

    context 'when conversion is a numeric' do
      let(:conv) { described_class.new(conversion: 0.3) }

      it 'returns the numeric' do
        expect(conv.conversion_of(nil)).to be(0.3)
      end
    end

    context 'when conversion is a hash' do
      let(:conv) { described_class.new(conversion: { electricity: 0.3 }) }

      it 'raises an errow when the parameter is nil' do
        expect { conv.conversion_of(nil) }.to raise_error(Atlas::MoleculeCarrierRequired)
      end

      it 'returns the numeric value when given a specified carrier' do
        expect(conv.conversion_of(:electricity)).to eq(0.3)
      end

      it 'returns 0.0 when given an unspecified carrier' do
        expect(conv.conversion_of(:gas)).to eq(0.0)
      end
    end
  end
end
