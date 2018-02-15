require 'spec_helper'

module Atlas; describe Scaler do
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

    context 'with scaling value #{ scaling_value }' do
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

      it 'sets the scaling base_value of the Derived to the number_of_residences in nl' do
        expect(derived_dataset.scaling[:base_value]).
          to eq(base_dataset.number_of_residences)
      end

      it 'assigns the correctly scaled number of residences' do
        expect(derived_dataset.number_of_residences).to eq(scaling_value)
      end

      it 'assigns the correctly scaled number of inhabitants' do
        expect(derived_dataset.number_of_inhabitants).to be_within(0.001).of(2249.185)
      end

      it 'dumps a graph.yml' do
        expect(derived_dataset.graph).to_not be_blank
      end

      describe 'graph.yml' do
        it 'scales down demand of node :a' do
          expect(derived_dataset.graph.node(:a).demand)
            .to eq(25 * scaling_factor)
        end

        it 'scales down demand of node :b' do
          expect(derived_dataset.graph.node(:b).demand)
            .to eq(10 * scaling_factor)
        end

        it 'scales down demand of edge :a->:b' do
          expect(
            derived_dataset.graph.node(:a).edges(:out).first.demand
          ).to eq(10 * scaling_factor)
        end
      end

      context 'with scaling_exempt set on node :b' do
        let(:graph) do
          super().tap do |gr|
            gr.node(:b).get(:model).scaling_exempt = true
          end
        end

        describe 'graph.yml' do
          it 'scales down demand of node :a' do
            expect(derived_dataset.graph.node(:a).demand)
              .to eq(25 * scaling_factor)
          end

          it 'retains the original demand of node :b' do
            expect(derived_dataset.graph.node(:b).demand).to eq(10)
          end

          it 'scales down demand of edge :a->:b' do
            expect(
              derived_dataset.graph.node(:a).edges(:out).first.demand
            ).to eq(10 * scaling_factor)
          end
        end
      end
    end

    context 'with scaling value nil' do
      let(:scaler) { Scaler.new('nl', 'ameland', nil) }

      it 'creates an invalid Derived' do
        expect { scaler.create_scaled_dataset }.
          to raise_error(Atlas::InvalidDocumentError, /Scaling Value/)
      end
    end
  end # create_scaled_dataset


  describe Scaler::GraphScaler do
    let(:scaled) { graph }

    before { Scaler::GraphScaler.new(scaling_factor).call(scaled) }

    it 'exports the correct demand 25 * scaling_factor for node :a' do
      expect(scaled.node(:a).demand).to eql(25.to_r * scaling_factor)
    end

    it 'exports the correct demand 10 * scaling_factor for edge :a->:b' do
      expect(scaled.node(:a).edges(:out).first.demand).
        to eql(10.to_r * scaling_factor)
    end
  end # GraphScaler


  describe Scaler::TimeCurveScaler do
    let(:scaling) {
      Preset::Scaling.new(
        base_value: 7_349_500,
        value: 1000,
        area: 'number_of_residences'
      )
    }

    let(:derived_dataset) do
      Atlas::Dataset::Derived.new(
        key: 'rotterdam', area: 'rotterdam', scaling: scaling)
    end

    before do
      Scaler::TimeCurveScaler.call(base_dataset, derived_dataset)
    end

    it 'scales the time curves' do
      expect(derived_dataset.time_curve(:woody_biomass).get(2030, :max_demand)).
        to be_within(0.001).of(9.73488372100000E+04 * scaling_factor)
    end

    it 'has the same columns as original file' do
      expect(derived_dataset.time_curve(:woody_biomass).column_keys).
        to eql(base_dataset.time_curve(:woody_biomass).column_keys)
    end

    it 'has a row for each year in the original file' do
      expect(derived_dataset.time_curve(:woody_biomass).row_keys).
        to eql(base_dataset.time_curve(:woody_biomass).row_keys)
    end
  end # TimeCurveScaler
end; end # Atlas::Scaler
