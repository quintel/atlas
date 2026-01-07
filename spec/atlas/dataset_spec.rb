require 'spec_helper'

module Atlas
  describe Dataset do
    describe "#new" do
      it "sets key" do
        dataset = Dataset.new(key: :nl)
        expect(dataset.key).to eq(:nl)
      end
    end

    describe "#find" do
      it "finds the Dutch dataset from file" do
        dataset = Dataset.find(:nl)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Full)
        expect(dataset.key).to eq(:nl)
      end

      it "finds the UK dataset from file" do
        dataset = Dataset.find(:uk)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Full)
        expect(dataset.key).to eq(:uk)
      end

      it "finds the Groningen dataset from file" do
        dataset = Dataset.find(:groningen)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Derived)
        expect(dataset.key).to eq(:groningen)
      end
    end

    describe '#dataset_dir' do
      describe "for a key" do
        let(:dataset) { Dataset.new(key: :kr) }

        it 'includes the data directory' do
          expect(dataset.dataset_dir.to_s).to include(Atlas.data_dir.to_s)
        end

        it 'ends with datasets' do
          expect(dataset.dataset_dir.to_s).to end_with('/datasets')
        end
      end

      describe "with a path" do
        let(:dataset) { Dataset.new(path: "test/test/kr") }

        it 'includes the data directory' do
          expect(dataset.dataset_dir.to_s).to include(Atlas.data_dir.to_s)
        end

        it 'ends with the last folder names' do
          expect(dataset.dataset_dir.to_s).to end_with('/test/test')
        end
      end
    end

    describe "#energy_balance" do
      it "has a energy_balance" do
        dataset = Dataset.find(:nl)
        expect(dataset.energy_balance).to be_a(EnergyBalance)
      end
    end

    describe '#shares' do
      let(:dataset) { Dataset.find(:nl) }
      let(:shares)  { dataset.shares(:electricity) }

      it 'returns a CSV document' do
        expect(shares).to be_a(CSVDocument)
      end

      it 'sets the file path' do
        expect(shares.path.to_s).to end_with('nl/shares/electricity.csv')
      end

      it 'raises an error when no shares data exists' do
        expect { Dataset.find(:nl).shares(:nope) }.to raise_error(Errno::ENOENT)
      end
    end

    describe '#efficiencies' do
      let(:dataset)      { Dataset.find(:nl) }
      let(:efficiencies) { dataset.efficiencies(:transformation) }

      it 'returns a CSV document' do
        expect(efficiencies).to be_a(CSVDocument)
      end

      it 'sets the file path' do
        expect(efficiencies.path.to_s).
          to end_with('nl/efficiencies/transformation_efficiency.csv')
      end

      it 'raises an error when no shares data exists' do
        expect { Dataset.find(:nl).efficiencies(:nope) }.
          to raise_error(Errno::ENOENT)
      end
    end

    describe '#load_profile_path' do
      let(:dataset) { Dataset.find(:nl) }
      let(:profile) { dataset.load_profile_path(:total_demand) }

      it 'returns a Pathname' do
        expect(profile).to be_a(Pathname)
      end

      it 'includes the dataset directory' do
        expect(profile.to_s).to start_with(dataset.dataset_dir.to_s)
      end
    end

    describe '#load_profile' do
      let(:dataset) { Dataset.find(:nl) }
      let(:profile) { dataset.load_profile(:total_demand) }

      it 'loads the curve with Util.load_curve' do
        allow(Atlas::Util).to(
          receive(:load_curve)
            .with(dataset.load_profile_path(:total_demand))
            .and_return('1.0')
        )

        expect(dataset.load_profile(:total_demand)).to eq('1.0')
      end
    end

    [1, 2, 3].each do |number|
      describe "#electric_vehicle_profile_#{ number }_share" do
        let(:dataset) { Dataset.new }
        let(:meth) { "electric_vehicle_profile_#{ number }_share" }

        it 'has an error when blank' do
          dataset.public_send("#{ meth }=", nil)

          dataset.valid?
          expect(dataset.errors[meth.to_sym]).to include('is not a number')
        end

        it 'has no error when a valid is present' do
          dataset.public_send("#{ meth }=", 1.0)

          dataset.valid?
          expect(dataset.errors[meth.to_sym]).to be_empty
        end
      end
    end

    describe 'electric vehicle shares' do
      let(:errors) do
        dataset.valid?
        dataset.errors[:electric_vehicle_profile_share]
      end

      context 'when the values sum to 1.0' do
        let(:dataset) do
          Dataset.new(
            electric_vehicle_profile_1_share: 0.3,
            electric_vehicle_profile_2_share: 0.4,
            electric_vehicle_profile_3_share: 0.3,
            electric_vehicle_profile_4_share: 0.0,
            electric_vehicle_profile_5_share: 0.0
          )
        end

        it 'has no error' do
          expect(errors).to be_empty
        end
      end

      context 'when the values sum to 0.8' do
        let(:dataset) do
          Dataset.new(
            electric_vehicle_profile_1_share: 0.3,
            electric_vehicle_profile_2_share: 0.2,
            electric_vehicle_profile_3_share: 0.3,
            electric_vehicle_profile_4_share: 0.0,
            electric_vehicle_profile_5_share: 0.0
          )
        end

        it 'has an error' do
          dataset.valid?

          expect(errors).to include(
            'contains electric_vehicle_profile_share attributes ' \
            'which sum to 0.8, but should sum to 1.0'
          )
        end
      end

      context 'when the values sum to 1.2' do
        let(:dataset) do
          Dataset.new(
            electric_vehicle_profile_1_share: 0.4,
            electric_vehicle_profile_2_share: 0.5,
            electric_vehicle_profile_3_share: 0.3,
            electric_vehicle_profile_4_share: 0.0,
            electric_vehicle_profile_5_share: 0.0
          )
        end

        it 'has an error' do
          dataset.valid?

          expect(errors).to include(
            'contains electric_vehicle_profile_share attributes ' \
            'which sum to 1.2, but should sum to 1.0'
          )
        end
      end
    end

    describe 'validate number of residences' do
      it 'is valid when the number of residence types is set correctly' do
        dataset = Dataset::Full.new(
          present_number_of_residences: 100,
          present_number_of_apartments_before_1945: 5,
          present_number_of_apartments_1945_1964: 5,
          present_number_of_apartments_1965_1984: 5,
          present_number_of_apartments_1985_2004: 5,
          present_number_of_apartments_2005_present: 5,
          present_number_of_detached_houses_before_1945: 5,
          present_number_of_detached_houses_1945_1964: 5,
          present_number_of_detached_houses_1965_1984: 5,
          present_number_of_detached_houses_1985_2004: 5,
          present_number_of_detached_houses_2005_present: 5,
          present_number_of_semi_detached_houses_before_1945: 5,
          present_number_of_semi_detached_houses_1945_1964: 5,
          present_number_of_semi_detached_houses_1965_1984: 5,
          present_number_of_semi_detached_houses_1985_2004: 5,
          present_number_of_semi_detached_houses_2005_present: 5,
          present_number_of_terraced_houses_before_1945: 5,
          present_number_of_terraced_houses_1945_1964: 5,
          present_number_of_terraced_houses_1965_1984: 5,
          present_number_of_terraced_houses_1985_2004: 5,
          present_number_of_terraced_houses_2005_present: 5
        )

        dataset.valid?
        expect(dataset.errors[:present_number_of_residences]).to be_empty
      end

      it 'is invalid when the number of residence types does not sum to number of residences' do
        dataset = Dataset::Full.new(
          present_number_of_residences: 100,
          present_number_of_apartments_before_1945: 1,
          present_number_of_apartments_1945_1964: 5,
          present_number_of_apartments_1965_1984: 5,
          present_number_of_apartments_1985_2004: 5,
          present_number_of_apartments_2005_present: 5,
          present_number_of_detached_houses_before_1945: 5,
          present_number_of_detached_houses_1945_1964: 5,
          present_number_of_detached_houses_1965_1984: 5,
          present_number_of_detached_houses_1985_2004: 5,
          present_number_of_detached_houses_2005_present: 5,
          present_number_of_semi_detached_houses_before_1945: 5,
          present_number_of_semi_detached_houses_1945_1964: 5,
          present_number_of_semi_detached_houses_1965_1984: 5,
          present_number_of_semi_detached_houses_1985_2004: 5,
          present_number_of_semi_detached_houses_2005_present: 5,
          present_number_of_terraced_houses_before_1945: 5,
          present_number_of_terraced_houses_1945_1964: 5,
          present_number_of_terraced_houses_1965_1984: 5,
          present_number_of_terraced_houses_1985_2004: 5,
          present_number_of_terraced_houses_2005_present: 5
        )

        dataset.valid?
        expect(dataset.errors[:present_number_of_residences]).to include(
          <<~ERROR.gsub(/\s+/, ' ').strip
            Number of residences per type and construction year don't add up to the total number of
            residences (100.0).
          ERROR
        )
      end
    end

    describe '#destroy!' do
      let(:dataset) { Dataset.find(:nl) }

      it 'removes the directory' do
        expect { dataset.destroy! }
          .to change { dataset.dataset_dir.exist? }
          .from(true).to(false)
      end
    end

    describe '#resolve_paths' do
      let(:datasets_dir) { Atlas.data_dir.join('datasets') }

      context 'for a base dataset' do
        let(:dataset_path) { datasets_dir.join('test_base.yml') }
        let(:dataset) { Dataset.new(path: dataset_path.to_s) }

        it 'returns an array with the dataset_dir' do
          expect(dataset.resolve_paths).to eq([dataset.dataset_dir])
        end
      end

      context 'for a derived dataset with a parent' do
        let(:parent_path) { datasets_dir.join('test_parent.yml') }
        let(:derived_path) { datasets_dir.join('test_derived.yml') }
        let(:parent) { Dataset.new(path: parent_path.to_s) }
        let(:derived) do
          d = Dataset.new(path: derived_path.to_s)
          allow(d).to receive(:parent).and_return(parent)
          allow(d).to receive(:respond_to?).with(:parent).and_return(true)
          d
        end

        it 'returns an array with its dataset_dir and parent resolve_paths' do
          expect(derived.resolve_paths).to eq(([derived.dataset_dir] + parent.resolve_paths).uniq)
        end
      end
    end
  end

    describe Dataset::Derived do
      describe "#valid?" do
        it "validates the existence of the base_dataset" do
          dataset = Dataset::Derived.new(key: :ameland, base_dataset: :fantasia)
          dataset.valid?
          expect(dataset.errors[:base_dataset]).to include('does not exist')
        end

        it "validates the existence of the scaling" do
          dataset = Dataset::Derived.new(key: :ameland, base_dataset: :fantasia)
          dataset.valid?
          expect(dataset.errors[:scaling]).to include("can't be blank")
        end
      end
    end
end
