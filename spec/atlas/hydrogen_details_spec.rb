# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::HydrogenDetails do
  let(:details) { described_class.new(attrs) }

  context 'with no type' do
    let(:attrs) { {} }

    it 'is invalid' do
      expect(details.errors_on(:type)).to include('is not included in the list')
    end
  end

  context 'with a type of :invalid' do
    let(:attrs) { { type: :invalid } }

    it 'is invalid' do
      expect(details.errors_on(:type)).to include('is not included in the list')
    end
  end

  context 'with a type of :consumer' do
    let(:attrs) { { type: :consumer, profile: :abc } }

    it 'is valid' do
      expect(details).to be_valid
    end

    it 'must have a profile' do
      details.profile = nil

      expect(details.errors_on(:profile)).to include("can't be blank")
    end
  end

  context 'with a type of :producer' do
    let(:attrs) { { type: :producer, profile: :abc } }

    it 'is valid' do
      expect(details).to be_valid
    end

    it 'must have a profile' do
      details.profile = nil
      expect(details.errors_on(:profile)).to include("can't be blank")
    end
  end

  context 'with a type of :storage' do
    let(:attrs) { { type: :storage } }

    it 'is valid' do
      expect(details).to be_valid
    end

    it 'may not have profile' do
      details.profile = :abc
      expect(details.error_on(:profile)).to include('must be blank')
    end
  end
end
