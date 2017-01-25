require 'spec_helper'

module Atlas; describe Dataset::DerivedDataset do
  let(:dataset) {
    Dataset::DerivedDataset.new(
      key: 'lutjebroek',
      base_dataset: 'nl',
      interconnector_capacity: 1.0,
      scaling: Preset::Scaling.new(
        area_attribute: 'number_of_residences',
        value: 1000,
        base_value: 10000
      )
    )
  }

  it 'is a valid dataset' do
    expect(dataset).to be_valid
  end

  describe '(validations)' do
    before do
      dataset.init = init
      dataset.valid?
    end

    describe 'with a non-existing initializer input' do
      let(:init) { { non_existing_key: 1.0 } }

      it "raises an error" do
        expect(dataset.errors_on(:init))
          .to include("initializer input 'non_existing_key' does not exist")
      end
    end

    describe 'with a blank value' do
      let(:init) { { initializer_input_mock: nil } }

      it "raises an error" do
        expect(dataset.errors_on(:init))
          .to include("value for initializer input 'initializer_input_mock' can't be blank")
      end
    end

    describe "share values don't add up to 100" do
      let(:init) { {
        households_space_heater_coal_share: 50.0,
        households_space_heater_crude_oil_share: 49.0
      } }

      it "raises an error" do
        expect(dataset.errors_on(:init))
          .to include("contains inputs belonging to the test_heating_households share group, but the values sum to 99.0, not 100")
      end
    end

    describe "not all share values are not defined" do
      let(:init) { { households_space_heater_coal_share: 100.0 } }

      it "raises an error" do
        expect(dataset.errors_on(:init))
          .to include("share group 'test_heating_households' is missing the following share(s): households_space_heater_crude_oil_share")
      end
    end
  end
end; end
