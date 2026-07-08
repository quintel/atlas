require 'spec_helper'

module Atlas
  describe SectorMapping do
    let(:mapping) { described_class.load }

    describe '.load' do
      it 'reads the mapping from the ETSource config directory' do
        expect(mapping.scheme_names)
          .to eq(%i[sector_label use ipcc_crt_code_agg klimaattafel])
      end

      it 'memoizes per data dir' do
        expect(described_class.load).to be(described_class.load)
      end
    end

    describe '.normalize' do
      it 'slugifies display values to symbols' do
        expect(described_class.normalize('Industrie')).to eq(:industrie)
      end

      it 'resolves quoted, bare and cased forms identically' do
        expect(described_class.normalize("'1.A.1'".delete("'")))
          .to eq(described_class.normalize('1.A.1'))
        expect(described_class.normalize('Industrie'))
          .to eq(described_class.normalize('industrie'))
      end

      it 'treats "-" and blank cells as no value' do
        expect(described_class.normalize('-')).to be_nil
        expect(described_class.normalize('')).to be_nil
        expect(described_class.normalize(nil)).to be_nil
      end

      it 'keeps numeric-looking codes matchable (float-converter guard)' do
        expect(described_class.normalize(2)).to eq(described_class.normalize('2'))
      end
    end

    describe '#lookup' do
      it 'returns the (label, use) pairs whose scheme cell matches the value' do
        expect(mapping.lookup(:klimaattafel, 'Industrie')).to contain_exactly(
          %i[industry_refineries energetic],
          %i[industry_refineries non_energetic],
          %i[industry_steel energetic]
        )
      end

      it 'namespaces values per column' do
        expect(mapping.lookup(:ipcc_crt_code_agg, '1.A.1')).to contain_exactly(
          %i[energy_electricity_and_heat_production energetic],
          %i[industry_refineries energetic]
        )
        # The same string in a different column resolves nothing.
        expect(mapping.lookup(:klimaattafel, '1.A.1')).to be_empty
      end

      it 'matches numeric-looking codes through the shared normalizer' do
        expect(mapping.lookup(:ipcc_crt_code_agg, '2'))
          .to contain_exactly(%i[industry_steel energetic])
      end

      it 'resolves the canonical key by the sector_label column' do
        expect(mapping.lookup(:sector_label, 'industry_refineries')).to contain_exactly(
          %i[industry_refineries energetic],
          %i[industry_refineries non_energetic]
        )
      end

      it 'raises for an unknown scheme, naming the valid ones' do
        expect { mapping.lookup(:impossible, 'x') }
          .to raise_error(KeyError, /Valid schemes.*klimaattafel/m)
      end
    end

    describe '#lookup with blank cells' do
      # Row `waste_non_specified,non_energetic` has a "-" ipcc cell;
      # row `energy_ccus,non_energetic` has a genuinely empty ipcc cell.

      it 'treats a "-" cell as unqueryable' do
        expect(mapping.lookup(:ipcc_crt_code_agg, '-')).to be_empty
      end

      it 'treats an empty cell as unqueryable' do
        expect(mapping.lookup(:ipcc_crt_code_agg, '')).to be_empty
      end

      it 'does not group "-" and empty cells into a shared phantom category' do
        # Both blank rows have a blank ipcc cell, but neither is reachable
        # through the ipcc column under any value (including the empty slug).
        blank_slug = described_class.normalize('')
        expect(blank_slug).to be_nil
        expect(mapping.lookup(:ipcc_crt_code_agg, blank_slug)).to be_empty
      end

      it 'still reaches a "-"-celled row through another scheme' do
        expect(mapping.lookup(:klimaattafel, 'Elektriciteit')).to contain_exactly(
          %i[energy_electricity_and_heat_production energetic],
          %i[waste_non_specified non_energetic]
        )
      end

      it 'still reaches an empty-celled row through another scheme' do
        expect(mapping.lookup(:klimaattafel, 'CCUS'))
          .to contain_exactly(%i[energy_ccus non_energetic])
      end
    end

    describe '#pairs' do
      it 'lists every (label, use) row, including shared labels and blank-celled rows' do
        expect(mapping.pairs).to include(
          %i[industry_refineries energetic],
          %i[industry_refineries non_energetic],
          %i[waste_non_specified non_energetic], # "-" ipcc cell
          %i[energy_ccus non_energetic]          # empty ipcc cell
        )
      end
    end

    describe 'load-time validation' do
      it 'rejects two values in one column that normalize identically' do
        csv = <<~CSV
          sector_label,use,klimaattafel
          a,energetic,Industrie
          b,energetic,industrie
        CSV

        expect { described_class.from_string(csv) }
          .to raise_error(SectorMappingSlugCollisionError, /industrie/)
      end

      it 'rejects a duplicated (sector_label, use) row' do
        csv = <<~CSV
          sector_label,use,klimaattafel
          a,energetic,Industrie
          a,energetic,Elektriciteit
        CSV

        expect { described_class.from_string(csv) }
          .to raise_error(DuplicateSectorMappingRowError, /a.*energetic/m)
      end

      it 'allows the same value to repeat across rows within a column' do
        csv = <<~CSV
          sector_label,use,klimaattafel
          a,energetic,Industrie
          b,energetic,Industrie
        CSV

        expect { described_class.from_string(csv) }.not_to raise_error
      end
    end
  end
end
