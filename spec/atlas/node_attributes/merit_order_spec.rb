# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::NodeAttributes::MeritOrder do
  let(:attrs) { {} }

  context 'when type=:flex' do
    let(:attrs) { super().merge(type: :flex) }

    describe '#group' do
      it 'must not be nil' do
        mod = described_class.new(attrs.merge(group: nil))

        expect(mod.errors_on(:group))
          .to include('is not a permitted flexibility order option')
      end

      it 'must not be empty' do
        mod = described_class.new(attrs.merge(group: ''))

        expect(mod.errors_on(:group))
          .to include('is not a permitted flexibility order option')
      end

      it 'may be a valid flexibility option as a string' do
        mod = described_class.new(attrs.merge(
          group: Atlas::Config.read('flexibility_order').first.to_s
        ))

        expect(mod.errors_on(:group)).to be_empty
      end

      it 'may be a valid flexibility option as a symbol' do
        mod = described_class.new(attrs.merge(
          group: Atlas::Config.read('flexibility_order').first.to_sym
        ))

        expect(mod.errors_on(:group)).to be_empty
      end

      it 'must not be an invalid flexibility option' do
        mod = described_class.new(attrs.merge(group: 'nope'))

        expect(mod.errors_on(:group))
          .to include('is not a permitted flexibility order option')
      end
    end
  end
end
