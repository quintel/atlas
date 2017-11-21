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
