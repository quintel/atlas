# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe SparseGraphQuery do
    describe '(find_by_graph)' do
      it 'finds a sparse graph query by graph key and method' do
        expect(
          SparseGraphQuery.find('bar+demand').key
        ).to eq(:"bar+demand")
      end
    end

    describe '(validations)' do
      let(:attributes) { {} }
      let(:query) do
        SparseGraphQuery.new({ key: 'test+demand' }.merge(attributes))
      end

      before { query.valid? }

      describe 'invalid' do
        it 'graph key when it does not exist' do
          expect(query.errors_on(:part))
            .to include('no such node, edge or scope exists: test')
        end

        describe 'graph attribute' do
          let(:attributes) { { key: 'bar+not_allowed' } }

          it 'is invalid' do
            expect(query.errors_on(:graph_method))
              .to include('is not included in the list')
          end
        end

        describe 'area attribute' do
          let(:attributes) { { key: 'area+not_allowed' } }

          it 'is invalid' do
            expect(query.errors_on(:graph_method))
              .to include('is not included in the list')
          end
        end
      end

      describe 'a valid' do
        describe 'node' do
          let(:attributes) { { key: 'bar+demand' } }

          it 'is valid' do
            expect(query).to be_valid
          end
        end

        describe 'edge' do
          let(:attributes) { { key: 'bar-baz@corn+parent_share' } }

          it 'is valid' do
            expect(query).to be_valid
          end
        end
      end
    end
  end
end
