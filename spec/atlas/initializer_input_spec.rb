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
end; end
