# frozen_string_literal: true

require 'spec_helper'

module Atlas
  describe Util do
    describe '.flatten_dotted_hash' do
      let(:dotted) { Atlas::Util.flatten_dotted_hash(hash) }

      context 'when the hash only contains one level' do
        let(:hash) { { a: 1, b: 2 } }

        it 'adds the first value' do
          expect(dotted[:a]).to be(1)
        end

        it 'adds the second value' do
          expect(dotted[:b]).to be(2)
        end
      end

      context 'when the hash contains two levels' do
        let(:hash) { { a: 1, b: { c: 3 } } }

        it 'adds the first value' do
          expect(dotted[:a]).to be(1)
        end

        it 'adds the second value' do
          expect(dotted['b.c']).to be(3)
        end

        it 'does not have a key for the first-level hash' do
          expect(dotted).not_to have_key(:b)
        end

        it 'does not have a key for the second-level value' do
          expect(dotted).not_to have_key(:c)
        end
      end

      context 'when the hash contains three levels' do
        let(:hash) { { a: 1, b: { c: { d: 4 } } } }

        it 'adds the first value' do
          expect(dotted[:a]).to be(1)
        end

        it 'adds the second value' do
          expect(dotted['b.c.d']).to be(4)
        end

        it 'does not have a key for the first-level hash' do
          expect(dotted).not_to have_key(:b)
        end

        it 'does not have a key for the second-level hash' do
          expect(dotted).not_to have_key('b.c')
        end

        it 'does not have a key for the second-level value' do
          expect(dotted).not_to have_key(:c)
        end

        it 'does not have a key for the third-level value' do
          expect(dotted).not_to have_key(:d)
        end
      end

      context 'when one of the values is an array' do
        context 'with only scalar values' do
          let(:hash) { { a: 1, b: [2, 3] } }

          it 'adds the scalar value' do
            expect(dotted[:a]).to be(1)
          end

          it 'adds the array value' do
            expect(dotted[:b]).to eql([2, 3])
          end
        end

        context 'with a hash as a value' do
          let(:hash) { { a: 1, b: [{ c: 2 }, 3] } }

          it 'raises an IllegalNestedHashError' do
            expect { dotted }.to raise_error(IllegalNestedHashError)
          end
        end
      end
    end

    describe '.expand_dotted_hash' do
      let(:expanded) { Atlas::Util.expand_dotted_hash(hash) }

      context 'when the hash contains only one level' do
        let(:hash) { { 'a' => 1, 'b' => 2 } }

        it 'adds the first value' do
          expect(expanded).to include(a: 1)
        end

        it 'adds the second value' do
          expect(expanded).to include(b: 2)
        end
      end

      context 'when the hash contains two levels' do
        let(:hash) { { 'a' => 1, 'b.c' => 3 } }

        it 'adds the scalar value' do
          expect(expanded).to include(a: 1)
        end

        it 'adds the first-level hash' do
          expect(expanded).to have_key(:b)
        end

        it 'adds the final value' do
          expect(expanded[:b]).to include(c: 3)
        end

        it 'does not add the dotted key' do
          expect(expanded).not_to have_key(:'b.c')
        end
      end

      context 'when the hash contains three levels' do
        let(:hash) { { 'a' => 1, 'b.c.d' => 4 } }

        it 'adds the scalar value' do
          expect(expanded).to include(a: 1)
        end

        it 'adds the first-level hash' do
          expect(expanded).to have_key(:b)
        end

        it 'adds the second-level hash' do
          expect(expanded[:b]).to have_key(:c)
        end

        it 'adds the final value' do
          expect(expanded[:b][:c]).to include(d: 4)
        end

        it 'does not add the dotted key' do
          expect(expanded).not_to have_key(:'b.c')
          expect(expanded).not_to have_key(:'b.c.d')
        end
      end
    end

    describe '.round_computation_errors' do
      let(:rounded) { Atlas::Util.round_computation_errors(@value) }

      it 'does not round 2.3' do
        @value = 2.3
        expect(rounded).to eq(@value)
      end

      it 'rounds 1.999999999 to 2' do
        @value = 1.999999999
        expect(rounded).to eq(2)
      end

      it 'rounds 2.000000001 to 2' do
        @value = 2.000000001
        expect(rounded).to eq(2)
      end

      it 'rounds -2.000000001 to -2' do
        @value = -2.000000001
        expect(rounded).to eq(-2)
      end

      it 'does not round 0.000000001' do
        @value = 0.000000001
        expect(rounded).to eq(@value)
      end

      it 'does not round -0.000000001' do
        @value = -0.000000001
        expect(rounded).to eq(@value)
      end
    end

    describe 'serializable_attributes' do
      let(:serialized) do
        Atlas::Util.serializable_attributes(
          int: 1,
          blank_str: ' ',
          non_blank_str: 'a',
          empty_arr: [],
          non_empty_arr: %w[a],
          empty_hash: {},
          non_empty_hash: { a: 1 },
          true_value: true,
          false_value: false,
          nil_value: nil
        )
      end

      it 'includes non-nil values' do
        expect(serialized[:int]).to eq(1)
      end

      it 'includes true' do
        expect(serialized[:true_value]).to be(true)
      end

      it 'includes false' do
        expect(serialized[:false_value]).to be(false)
      end

      it 'omits nil' do
        expect(serialized).not_to have_key(:nil_value)
      end

      it 'omits blank strings' do
        expect(serialized).not_to have_key(:blank_str)
      end

      it 'includes non-blank strings' do
        expect(serialized[:non_blank_str]).to eq('a')
      end

      it 'omits empty arrays' do
        expect(serialized).not_to have_key(:empty_arr)
      end

      it 'includes non-empty arrays' do
        expect(serialized[:non_empty_arr]).to eq(%w[a])
      end

      it 'omits empty hashes' do
        expect(serialized).not_to have_key(:empty_hash)
      end

      it 'includes non-empty hashes' do
        expect(serialized[:non_empty_hash]).to eq(a: 1)
      end
    end
  end
end
