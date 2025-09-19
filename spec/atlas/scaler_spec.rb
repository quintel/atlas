require 'spec_helper'

module Atlas
  RSpec.describe Scaler do
    include GraphHelper

    # Graph:
    # [ a (25) ]--< a_b (10) >--[ b (10) ]

    let(:graph) do
      Turbine::Graph.new.tap do |graph|
        a = graph.add(make_node(:a, demand: 25))
        b = graph.add(make_node(:b, demand: 10))
        make_edge(a, b, :a_b, child_share: 1.0, demand: 10)
      end
    end

    before { allow(GraphBuilder).to receive(:build).and_return(graph) }

    let(:base_dataset) { Atlas::Dataset.find('nl') }

    let(:scaling_value) { 1000 }
    let(:scaling_factor) { scaling_value.to_r / 7_349_500 }

    describe '#create_scaled_dataset' do
      context "with scaling value" do
        let(:scaler) { Scaler.new('nl', 'ameland', scaling_value) }

        before { scaler.create_scaled_dataset }

        let(:derived_dataset) { Atlas::Dataset::Derived.find('ameland') }

        it 'creates a valid Derived' do
          derived_dataset.valid?

          expect(derived_dataset.errors).to be_empty
        end

        it 'assigns a new id to the Derived' do
          datasets = Atlas::Dataset.all
          old_max = (datasets - [derived_dataset]).map(&:id).max
          expect(derived_dataset.id).to be > old_max
        end

        it 'assigns the new id also as parent_id' do
          expect(derived_dataset.parent_id).to eq(derived_dataset.id)
        end

        it 'sets the scaling value of the Derived to #{ scaling_value }' do
          expect(derived_dataset.scaling[:value]).to eq(scaling_value)
        end

        it 'sets the scaling base_value of the Derived to the number_of_inhabitants in nl' do
          expect(derived_dataset.scaling[:base_value]).
            to eq(base_dataset.number_of_inhabitants)
        end

        it 'assigns the correctly scaled number of inhabitants' do
          expect(derived_dataset.number_of_inhabitants).to eq(scaling_value)
        end

        it 'assigns the correctly scaled number of inhabitants' do
          expect(derived_dataset.number_of_inhabitants).to be_within(0.001).of(1000.0)
        end
      end

      context 'with scaling value nil' do
        let(:scaler) { Scaler.new('nl', 'ameland', nil) }

        it 'creates an invalid Derived' do
          expect { scaler.create_scaled_dataset }.
            to raise_error(Atlas::InvalidDocumentError, /Scaling Value/)
        end
      end
    end

    describe 'double-derived scaling' do
      let(:base_dataset) { Atlas::Dataset::Full.find('nl') }
      let(:groningen_scaling_value) { 1000 }
      let(:winschoten_scaling_value) { 100 }
      let(:attribute) { :present_number_of_apartments_2005_present }

      before do
        # Stub graph_values validation for all Derived datasets
        allow_any_instance_of(Atlas::Dataset::Derived).to receive(:graph_values).and_return(double(valid?: true, errors: {}))

        # Create Groningen derived from NL
        groningen_scaler = Scaler.new('nl', 'groningen_test', groningen_scaling_value, 10000)
        groningen_scaler.create_scaled_dataset

        # Create Winschoten derived from Groningen
        winschoten_scaler = Scaler.new('groningen_test', 'winschoten_test', winschoten_scaling_value, 1000)
        winschoten_scaler.create_scaled_dataset
      end

      let(:groningen_test) { Atlas::Dataset::Derived.find('groningen_test') }
      let(:winschoten_test) { Atlas::Dataset::Derived.find('winschoten_test') }

      it 'scales the attribute cumulatively (compound scaling)' do
        base_value = base_dataset[attribute]
        groningen_factor = groningen_test.scaling.value.to_f / groningen_test.scaling.base_value.to_f
        winschoten_factor = winschoten_test.scaling.value.to_f / winschoten_test.scaling.base_value.to_f

        expected_groningen = base_value * groningen_factor
        expected_winschoten = base_value * groningen_factor * winschoten_factor

        expect(groningen_test[attribute]).to be_within(1e-6).of(expected_groningen)
        expect(winschoten_test[attribute]).to be_within(1e-6).of(expected_winschoten)
      end
    end
  end
end
