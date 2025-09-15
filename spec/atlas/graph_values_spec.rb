require 'spec_helper'

module Atlas; describe GraphValues do
  let(:dataset) {
    Dataset::Derived.new(
      key: 'lutjebroek',
      base_dataset: 'nl',
      interconnector_capacity: 1.0,
      scaling: Atlas::Dataset::Scaling.new(
        area_attribute: 'present_number_of_residences',
        value: 1000,
        base_value: 10000
      )
    )
  }

  let(:graph_values) { GraphValues.new(dataset) }

  describe "getting a value" do
    before do
      expect(graph_values).to receive(:values).once
        .and_return(values)
    end

    context "of a node" do
      let(:values) { { 'bar' => { 'demand' => 20.0 } } }
      let(:node)   { Atlas::EnergyNode.find(:bar) }

      it "all" do
        expect(graph_values.for(node)).to eq('demand' => 20.0)
      end

      it "specific attributes" do
        expect(graph_values.for(node, :demand)).to eq(20.0)
      end
    end
  end

  describe "setting a value" do
    before do
      expect(graph_values).to receive(:values).at_least(:once)
        .and_return(values)
    end

    context "of a node" do
      let(:values) { {} }

      it "(demand)" do
        node = Atlas::EnergyNode.find(:bar)

        graph_values.set(node.key.to_s, :demand, 50.0)
        graph_values.save

        expect(graph_values.to_h['bar']['demand']).to eq(50.0)
      end
    end

    context "of an existing node" do
      let(:values) {
        { 'bar' => { 'demand' => 20.0 } }
      }

      it "(demand)" do
        node = Atlas::EnergyNode.find(:bar)

        graph_values.set(node.key.to_s, :demand, 50.0)
        graph_values.save

        expect(graph_values.to_h['bar']['demand']).to eq(50.0)
      end
    end

    context "of a slot share" do
      let(:values) {
        { 'bar' => { 'input' => { 'gas' => 0.5 } } }
      }

      it "(electricity)" do
        node = Atlas::EnergyNode.find(:bar)

        graph_values.set(node.key.to_s, 'input', { 'electricity' => 0.5 })
        graph_values.save

        expect(graph_values.to_h['bar']['input']).to eq({
          'gas' => 0.5, 'electricity' => 0.5
        })
      end
    end
  end

  describe "(validations)" do
    describe "graph_values" do
      before do
        expect(graph_values).to receive(:values).at_least(:once)
          .and_return(values)

        graph_values.valid?
      end

      describe 'with a non-existing initializer input' do
        let(:values) { { test: { non_existing_key: 1.0 } } }

        it "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("'non_existing_key' does not exist as a graph method")
        end
      end

      describe 'with a blank value' do
        let(:values) { { input_mock: nil } }

        it "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("value for node/edge/slot 'input_mock' can't be blank")
        end
      end

      describe "share values don't add up to 1" do
        let(:values) {
          { 'bar-baz@corn': { 'parent_share' => 0.5 },
            'bar-fd@coal': { 'parent_share' => 0.49 }
          }
        }

        xit "raises an error" do
          expect(graph_values.errors_on(:values)).to include(
            'contains inputs belonging to the bar share group, but the values sum to 0.99, not 1.0'
          )
        end
      end

      describe "not all share values are not defined" do
        let(:values) {
          { 'bar-baz@corn': { 'parent_share' => 1.0  } }
        }

        xit "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("share group 'bar' is missing the following share(s): bar-fd@coal")
        end
      end

      describe "activating edges which aren't allowed" do
        let(:values) {
          { 'baz-fd@corn' => { 'share' => 1.0 } }
        }

        it "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("edge 'baz-fd@corn' is not allowed to be edited by 'share'")
        end
      end

      describe "activating nodes which aren't allowed" do
        let(:values) {
          { 'baz' => { 'demand' => 100.0 } }
        }

        it "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("node 'baz' is not allowed to be edited by 'demand'")
        end
      end

      describe "activating nodes which aren't allowed" do
        let(:values) {
          { 'baz' => { 'input' => { 'corn' => 100.0 } } }
        }

        it "raises an error" do
          expect(graph_values.errors_on(:values))
            .to include("node 'baz' is not allowed to be edited by 'input'")
        end
      end
    end
  end
end; end
