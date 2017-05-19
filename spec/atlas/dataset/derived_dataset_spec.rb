require 'spec_helper'

module Atlas; describe Dataset::Derived do
  let(:dataset) {
    Dataset::Derived.new(
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

  describe '#graph_path' do
    let(:dataset) {
      Dataset::Derived.new(
        path: 'lutjebroek/lutjebroek',
        base_dataset: 'nl'
      )
    }

    it "graph.yml lives in the root directory of the dataset" do
      expect(dataset.graph_path.to_s).to end_with("lutjebroek/graph.yml")
    end
  end

  describe '(validations)' do
    describe "init" do
      before do
        dataset.init = init
        dataset.valid?
      end

      describe 'with a non-existing initializer input' do
        let(:init) { { non_existing_key: 1.0 } }

        it "raises an error" do
          expect(dataset.errors_on(:init))
            .to include("'non_existing_key' does not exist as an initializer input")
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

    describe "graph" do
      describe "serialized" do
        let(:dataset) { Dataset::Derived.find(:groningen) }

        before do
          expect(dataset).to receive(:graph_path).at_least(:once)
            .and_return(Pathname.new("spec/fixtures/graphs/#{ graph }.yml"))

          dataset.valid?
        end

        describe "presence of the graph.yml file" do
          let(:graph) { "_non_existent_graph_" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("graph.yml file is missing")
          end
        end

        describe "missing node in the graph.yml" do
          let(:graph) { "graph" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following nodes are missing in the snapshot of"\
                          " the graph: my_residence")
          end
        end

        describe "missing edge in the graph.yml" do
          let(:graph) { "graph_missing_edges" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following edges are missing in the snapshot of"\
                          " the graph: foo-bar@coal")
          end
        end

        # Misses coal slot for 'fd' node
        describe "missing slot in the graph.yml" do
          let(:graph) { "graph_missing_slots" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following slots for fd are missing in the snapshot of"\
                          " the graph: coal")
          end
        end
      end
    end
  end

  describe "find by geo_id" do
    let(:dataset) { Dataset::Derived.find(:groningen) }

    it "find by geo id" do
      expect(Dataset::Derived.find_by_geo_id("test")).to eq(dataset)
    end
  end
end; end
