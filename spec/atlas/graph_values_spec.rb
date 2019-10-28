# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe GraphValues do
    let(:dataset) do
      Dataset::Derived.new(
        key: 'lutjebroek',
        base_dataset: 'nl',
        interconnector_capacity: 1.0,
        scaling: Preset::Scaling.new(
          area_attribute: 'number_of_residences',
          value: 1000,
          base_value: 10_000
        )
      )
    end

    let(:graph_values) { GraphValues.new(dataset) }

    describe 'getting a value' do
      before do
        expect(graph_values).to receive(:values).once
          .and_return(values)
      end

      context 'of a node' do
        let(:values) { { 'bar' => { 'demand' => 20.0 } } }
        let(:node)   { Atlas::Node.find(:bar) }

        it 'all' do
          expect(graph_values.for(node)).to eq('demand' => 20.0)
        end

        it 'specific attributes' do
          expect(graph_values.for(node, :demand)).to eq(20.0)
        end
      end
    end

    describe 'setting a value' do
      before do
        expect(graph_values).to receive(:values).at_least(:once)
          .and_return(values)
      end

      context 'of a node' do
        let(:values) { {} }

        it '(demand)' do
          node = Atlas::Node.find(:bar)

          graph_values.set(node.key.to_s, :demand, 50.0)
          graph_values.save

          expect(graph_values.to_h['bar']['demand']).to eq(50.0)
        end
      end

      context 'of an existing node' do
        let(:values) do
          { 'bar' => { 'demand' => 20.0 } }
        end

        it '(demand)' do
          node = Atlas::Node.find(:bar)

          graph_values.set(node.key.to_s, :demand, 50.0)
          graph_values.save

          expect(graph_values.to_h['bar']['demand']).to eq(50.0)
        end
      end

      context 'of a slot share' do
        let(:values) do
          { 'bar' => { 'input' => { 'gas' => 0.5 } } }
        end

        it '(electricity)' do
          node = Atlas::Node.find(:bar)

          graph_values.set(node.key.to_s, 'input', 'electricity' => 0.5)
          graph_values.save

          expect(graph_values.to_h['bar']['input']).to eq(
            'gas' => 0.5, 'electricity' => 0.5
          )
        end
      end
    end

    describe '(validations)' do
      describe 'graph_values' do
        before do
          expect(graph_values).to receive(:values).at_least(:once)
            .and_return(values)

          graph_values.valid?
        end

        describe 'with a non-existing initializer input' do
          let(:values) { { test: { non_existing_key: 1.0 } } }

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("'non_existing_key' does not exist as a graph method")
          end
        end

        describe 'with a blank value' do
          let(:values) { { input_mock: nil } }

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("value for node/edge/slot 'input_mock' can't be blank")
          end
        end

        describe "share values don't add up to 100" do
          let(:values) do
            { 'bar-baz@corn': { 'share' => 50.0 },
              'bar-fd@coal': { 'share' => 49.0 } }
          end

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include('contains inputs belonging to the bar share group, but the values sum to 99.0, not 100')
          end
        end

        describe 'not all share values are not defined' do
          let(:values) do
            { 'bar-baz@corn': { 'share' => 100.0 } }
          end

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("share group 'bar' is missing the following share(s): bar-fd@coal")
          end
        end

        describe "activating edges which aren't allowed" do
          let(:values) do
            { 'baz-fd@corn' => { 'share' => 100.0 } }
          end

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("edge 'baz-fd@corn' is not allowed to be edited by 'share'")
          end
        end

        describe "activating nodes which aren't allowed" do
          let(:values) do
            { 'baz' => { 'demand' => 100.0 } }
          end

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("node 'baz' is not allowed to be edited by 'demand'")
          end
        end

        describe "activating nodes which aren't allowed" do
          let(:values) do
            { 'baz' => { 'input' => { 'corn' => 100.0 } } }
          end

          it 'raises an error' do
            expect(graph_values.errors_on(:values))
              .to include("node 'baz' is not allowed to be edited by 'input'")
          end
        end
      end
    end
  end; end
