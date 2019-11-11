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

    describe '#time_curve' do
      let(:dataset) { Dataset.find(:nl) }
      let(:curves)  { dataset.time_curve(:woody_biomass) }

      it 'returns a CSV document' do
        expect(curves).to be_a(CSVDocument)
      end

      it 'sets the file path' do
        expect(curves.path.to_s).
          to end_with('nl/time_curves/woody_biomass_time_curve.csv')
      end

      it 'raises an error when no time curve data exists' do
        expect { Dataset.find(:nl).time_curve(:nope) }.to raise_error(Errno::ENOENT)
      end
    end

    describe '#time_curves' do
      let(:dataset) { Dataset.find(:nl) }

      describe 'when no curves have been loaded' do
        it 'loads all the time curves' do
          expect(dataset.time_curves.length).to eq(2)
        end

        it "doesn't include the 'time_curve' suffix in each key" do
          keys = dataset.time_curves.keys

          expect(keys.length).to eq(2)
          expect(keys).to include(:woody_biomass)
          expect(keys).to include(:coal)
        end
      end

      describe 'when a curve has already been loaded' do
        let!(:loaded) { dataset.time_curve(:woody_biomass) }

        it 'loads all the time curves' do
          expect(dataset.time_curves.length).to eq(2)
        end

        it "reuses the already-loaded curve" do
          expect(dataset.time_curves.values).to include(loaded)
        end
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

    describe '#insulation_costs' do
      let(:dataset) { Dataset.find(:nl) }

      context 'with "existing_apartments"' do
        it 'loads the upgrade costs for apartments' do
          expect(dataset.insulation_costs('existing_apartments'))
            .to be_a(Atlas::Dataset::InsulationCostCSV)
        end
      end

      context 'with "new_builds"' do
        it 'loads the new build costs for apartments' do
          expect(dataset.insulation_costs(:new_builds))
            .to be_a(Atlas::Dataset::InsulationCostCSV)
        end
      end

      context 'with "nope"' do
        it 'raises an error' do
          expect { dataset.insulation_costs('nope') }
            .to raise_error(Errno::ENOENT)
        end
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
          number_of_residences: 100,
          number_of_detached_houses: 20,
          number_of_apartments: 20,
          number_of_semi_detached_houses: 20,
          number_of_corner_houses: 20,
          number_of_terraced_houses: 20
        )

        dataset.valid?
        expect(dataset.errors[:number_of_residences]).to be_empty
      end

      it 'is invalid when the number of residence types does not sum to number of residences' do
        dataset = Dataset::Full.new(
          number_of_residences: 100,
          number_of_detached_houses: 19,
          number_of_apartments: 20,
          number_of_semi_detached_houses: 20,
          number_of_corner_houses: 20,
          number_of_terraced_houses: 20
        )

        dataset.valid?
        expect(dataset.errors[:number_of_residences]).to include(
          <<~ERROR.gsub(/\s+/, ' ').strip
            Number of apartments (20.0) Number of terraced houses (20.0) Number
            of corner houses (20.0) Number of detached houses (19.0) Number of
            semi detached houses (20.0) don't add up to the total number of
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
