require 'spec_helper'

module Tome
  describe Util do
    describe '.flatten_dotted_hash' do
      let(:dotted) { Tome::Util.flatten_dotted_hash(hash) }

      context 'when the hash only contains one level' do
        let(:hash) { { a: 1, b: 2 } }

        it 'adds the first value' do
          expect(dotted[:a]).to eql(1)
        end

        it 'adds the second value' do
          expect(dotted[:b]).to eql(2)
        end
      end # when the hash only contains one level

      context 'when the hash contains two levels' do
        let(:hash) { { a: 1, b: { c: 3 } } }

        it 'adds the first value' do
          expect(dotted[:a]).to eql(1)
        end

        it 'adds the second value' do
          expect(dotted['b.c']).to eql(3)
        end

        it 'does not have a key for the first-level hash' do
          expect(dotted).to_not have_key(:b)
        end

        it 'does not have a key for the second-level value' do
          expect(dotted).to_not have_key(:c)
        end
      end # when the hash contains two levels

      context 'when the hash contains three levels' do
        let(:hash) { { a: 1, b: { c: { d: 4 } } } }

        it 'adds the first value' do
          expect(dotted[:a]).to eql(1)
        end

        it 'adds the second value' do
          expect(dotted['b.c.d']).to eql(4)
        end

        it 'does not have a key for the first-level hash' do
          expect(dotted).to_not have_key(:b)
        end

        it 'does not have a key for the second-level hash' do
          expect(dotted).to_not have_key('b.c')
        end

        it 'does not have a key for the second-level value' do
          expect(dotted).to_not have_key(:c)
        end

        it 'does not have a key for the third-level value' do
          expect(dotted).to_not have_key(:d)
        end
      end # when the hash contains three levels

      context 'when one of the values is an array' do
        context 'with only scalar values' do
          let(:hash) { { a: 1, b: [2, 3] } }

          it 'adds the scalar value' do
            expect(dotted[:a]).to eql(1)
          end

          it 'adds the array value' do
            expect(dotted[:b]).to eql([2, 3])
          end
        end # with only scalar values

        context 'with a hash as a value' do
          let(:hash) { { a: 1, b: [{ c: 2 }, 3] } }

          it 'raises an IllegalNestedHashError' do
            expect { dotted }.to raise_error(IllegalNestedHashError)
          end
        end # with a hash as a value
      end # when one of the values is an array
    end # flatten_dotted_hash

    describe 'expand_dotted_hash' do
      let(:expanded) { Tome::Util.expand_dotted_hash(hash) }

      context 'when the hash contains only one level' do
        let(:hash) { { 'a' => 1, 'b' => 2 } }

        it 'adds the first value' do
          expect(expanded).to include(a: 1)
        end

        it 'adds the second value' do
          expect(expanded).to include(b: 2)
        end
      end # when the hash contains only one level

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
          expect(expanded).to_not have_key(:'b.c')
        end
      end # when the hash contains two levels

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
          expect(expanded).to_not have_key(:'b.c')
          expect(expanded).to_not have_key(:'b.c.d')
        end
      end # when the hash contains three levels
    end # expand_dotted_hash
  end # Util
end # Tome
