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
    describe "graph_values" do
      before do
        expect(dataset).to receive(:graph_values).at_least(:once)
          .and_return(graph_values)

        expect(dataset).to receive(:persisted?).at_least(:once)
          .and_return(true)

        expect(dataset).to receive(:graph_path).at_least(:once)
          .and_return(Pathname.new("spec/fixtures/graphs/graph.yml"))

        dataset.valid?
      end

      describe "blank" do
        let(:graph_values) { {} }

        it "should be valid" do
          expect(dataset).to be_valid
        end
      end

      describe 'with a non-existing initializer input' do
        let(:graph_values) { { non_existing_key: { test: 1.0 } } }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("'non_existing_key' does not exist as a graph method")
        end
      end

      describe 'with a blank value' do
        let(:graph_values) { { input_mock: nil } }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("value for graph method 'input_mock' can't be blank")
        end
      end

      describe "share values don't add up to 100" do
        let(:graph_values) {
          { 'share_setter' => {
            'bar-baz@corn': 50.0,
            'bar-fd@coal': 49.0
          } }
        }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("contains inputs belonging to the bar share group, but the values sum to 99.0, not 100")
        end
      end

      describe "not all share values are not defined" do
        let(:graph_values) {
          { 'share_setter' => {
            'bar-baz@corn': 100.0
          } }
        }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("share group 'bar' is missing the following share(s): bar-fd@coal")
        end
      end

      describe "activating edges which aren't allowed" do
        let(:graph_values) {
          { 'share_setter' => {
            'baz-fd@corn' => 100.0
          } }
        }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("edge 'baz-fd@corn' is not allowed to be edited by 'share_setter'")
        end
      end

      describe "activating nodes which aren't allowed" do
        let(:graph_values) {
          { 'demand_setter' => {
            'bar' => 100.0
          } }
        }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("node 'bar' is not allowed to be edited by 'demand_setter'")
        end
      end

      describe "activating nodes which aren't allowed" do
        let(:graph_values) {
          { 'conversion_setter' => {
            'bar@coal' => 100.0
          } }
        }

        it "raises an error" do
          expect(dataset.errors_on(:graph_values))
            .to include("slot 'bar@coal' is not allowed to be edited by 'conversion_setter'")
        end
      end
    end

    describe "graph" do
      describe "serialized" do
        let(:dataset) { Dataset::Derived.find(:groningen) }

        before do
          expect(dataset).to receive(:graph_path).at_least(:once)
            .and_return(Pathname.new("spec/fixtures/graphs/#{ graph }.yml"))
        end

        describe "presence of the graph.yml file" do
          let(:graph) { "_non_existent_graph_" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("graph.yml file is missing")
          end
        end

        describe "missing node in the graph.yml" do
          let(:graph) { "graph_missing_node" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following nodes are missing in the snapshot " \
                          "of the graph: my_residence")
          end
        end

        describe "missing node in the graph" do
          let(:graph) { "graph_extra_node" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following nodes are missing in the " \
                          "graph: my_residence_2")
          end
        end

        describe "missing edge in the graph.yml" do
          let(:graph) { "graph_missing_edges" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following edges are missing in the snapshot " \
                          "of the graph: foo-bar@coal")
          end
        end

        describe "missing edge in the graph" do
          let(:graph) { "graph_extra_edge" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following edges are missing in the " \
                          "graph: foo-my_residence@coal")
          end
        end

        # Misses coal slot for 'fd' node
        describe "missing slot in the graph.yml" do
          let(:graph) { "graph_missing_slots" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following slots for fd are missing in the " \
                          "snapshot of the graph: coal")
          end
        end

        # Misses coal slot for 'fd' node
        describe "missing slot in the graph" do
          let(:graph) { "graph_extra_slot" }

          it "raises an error" do
            expect(dataset.errors_on(:graph))
              .to include("the following slots for baz are missing in the " \
                          "graph: coal")
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
