require 'spec_helper'

RSpec.describe Atlas::ReconciliationDetails do
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

    it 'must not have an subordinate_to value' do
      details.subordinate_to = :bar

      expect(details.errors_on(:subordinate_to)).to include("must be blank")
    end

    it 'must not have an subordinate_to_output value' do
      details.subordinate_to_output = :ueable_heat

      expect(details.errors_on(:subordinate_to_output))
        .to include('must be blank')
    end
  end

  context 'with a consumer and subordinate attributes' do
    let(:attrs) do
      {
        type: :consumer,
        behavior: :subordinate,
        subordinate_to: :bar,
        subordinate_to_output: :useable_heat,
        profile: :abc
      }
    end

    it 'is valid' do
      expect(details).to be_valid
    end

    it 'must reference a valid node' do
      details.subordinate_to = :invalid

      expect(details.errors_on(:subordinate_to))
        .to include('references a node which does not exist')
    end

    it 'must have an subordinate_to_output value' do
      details.subordinate_to_output = nil

      expect(details.errors_on(:subordinate_to_output))
        .to include("can't be blank")
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

    context 'with a behavior of :subordinate' do
      let(:attrs) { { type: :producer, behavior: :subordinate } }

      it 'is not valid' do
        expect(details).not_to be_valid
      end
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
