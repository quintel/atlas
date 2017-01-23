require 'spec_helper'

module Atlas; describe Dataset::DerivedDataset do
  let(:dataset) { Dataset::DerivedDataset.find('groningen') }

  it 'is a DerivedDataset instance' do
    expect(dataset).to be_a(Dataset::DerivedDataset)
  end

  describe 'has initializer inputs' do
    let(:initializer_input) { dataset.initializer_inputs.first.first }

    it 'expects the correct type' do
      expect(initializer_input).to be_a(InitializerInput)
    end
  end
end; end
