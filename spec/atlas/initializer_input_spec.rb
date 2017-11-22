require 'spec_helper'

module Atlas; describe InitializerInput do
  it 'should be invalid' do
    invalid_initializer_input = InitializerInput.find('invalid_initializer_input')

    expect(invalid_initializer_input.valid?).to eq(false)
  end

  it 'should be valid with a single query' do
    initializer_input = InitializerInput.find('initializer_input_mock')

    expect(initializer_input.valid?).to eq(true)
  end

  describe 'validate update_type' do
    let(:initializer_input) { InitializerInput.new(query: '-', key: 'test') }

    it 'is valid when nil' do
      initializer_input.update_type = nil

      expect(initializer_input).to be_valid
    end

    it 'is valid when factor' do
      initializer_input.update_type = 'factor'

      expect(initializer_input).to be_valid
    end

    it 'is valid when %' do
      initializer_input.update_type = '%'

      expect(initializer_input).to be_valid
    end

    it 'is invalid when anything else' do
      initializer_input.update_type = 'invalid'

      expect(initializer_input).to be_invalid
    end
  end
end; end
