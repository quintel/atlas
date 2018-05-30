require 'spec_helper'

module Atlas
  describe Dataset do
    describe "#new" do
      it "sets key" do
        dataset = Dataset.new(key: :nl)
        expect(dataset.key).to eql(:nl)
      end
    end # describe #new

    describe "#find" do
      it "finds the Dutch dataset from file" do
        dataset = Dataset.find(:nl)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Full)
        expect(dataset.key).to eql(:nl)
      end

      it "finds the UK dataset from file" do
        dataset = Dataset.find(:uk)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Full)
        expect(dataset.key).to eql(:uk)
      end

      it "finds the Groningen dataset from file" do
        dataset = Dataset.find(:groningen)
        expect(dataset).to be_a(Dataset)
        expect(dataset).to be_a(Dataset::Derived)
        expect(dataset.key).to eql(:groningen)
      end
    end # describe #load

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
    end # shares

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
    end # efficiencies

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
    end # time_curve

    describe '#time_curves' do
      let(:dataset) { Dataset.find(:nl) }

      describe 'when no curves have been loaded' do
        it 'loads all the time curves' do
          expect(dataset.time_curves).to have(2).csv_documents
        end

        it "doesn't include the 'time_curve' suffix in each key" do
          keys = dataset.time_curves.keys

          expect(keys.length).to eq(2)
          expect(keys).to include(:woody_biomass)
          expect(keys).to include(:coal)
        end
      end # when no curves have been loaded

      describe 'when a curve has already been loaded' do
        let!(:loaded) { dataset.time_curve(:woody_biomass) }

        it 'loads all the time curves' do
          expect(dataset.time_curves).to have(2).csv_documents
        end

        it "reuses the already-loaded curve" do
          expect(dataset.time_curves.values).to include(loaded)
        end
      end # when a curves has already been loaded
    end # time_curves

    describe '#load_profile_path' do
      let(:dataset) { Dataset.find(:nl) }
      let(:profile) { dataset.load_profile_path(:total_demand) }

      it 'returns a Pathname' do
        expect(profile).to be_a(Pathname)
      end

      it 'includes the dataset directory' do
        expect(profile.to_s).to start_with(dataset.dataset_dir.to_s)
      end
    end # load_profile_path

    describe '#load_profile' do
      let(:dataset) { Dataset.find(:nl) }
      let(:profile) { dataset.load_profile(:total_demand) }

      describe 'when Merit has been loaded' do
        before do
          profile_const = double('LoadProfile')
          allow(profile_const).to receive(:load).and_return('my profile')

          stub_const('Merit::LoadProfile', profile_const)
        end

        it 'returns the load profile' do
          expect(profile).to eq('my profile')
        end
      end # when Merit has been loaded

      describe 'when Merit has not been loaded' do
        it 'raises a MeritRequired error' do
          expect { profile }.to raise_error(Atlas::MeritRequired)
        end
      end # when Merit has not been loaded
    end # load_profile

    describe '#capacity_distribution' do
      let(:dataset) { Dataset.find(:nl) }

      context 'with a real cap. dist.' do
        let(:dist) do
          dataset.capacity_distribution(:network_hv_mv_trafo_distribution)
        end

        it 'returns an array of values' do
          expect(dist).to eq([0.0, 0.09, 0.13, 0.16])
        end
      end

      context 'when the cap. dist. does not exist' do
        let(:dist) { dataset.capacity_distribution(:nope) }

        it 'raises an error' do
          expect { dist }.to raise_error(Errno::ENOENT)
        end
      end
    end # capacity_distribution

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
            electric_vehicle_profile_3_share: 0.3
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
            electric_vehicle_profile_3_share: 0.3
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
            electric_vehicle_profile_3_share: 0.3
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

    describe "validate number of residences" do
      it "validates if the number of old and new residences is set correctly" do
        dataset = Dataset::Full.new(number_of_residences: 100,
                                    number_of_old_residences: 5,
                                    number_of_new_residences: 95)

        dataset.valid?
        expect(dataset.errors[:number_of_residences]).to be_empty
      end

      it "validates if the number of old and new residences is set correctly" do
        dataset = Dataset::Full.new(number_of_residences: 100,
                                    number_of_old_residences: 5,
                                    number_of_new_residences: 94)

        dataset.valid?
        expect(dataset.errors[:number_of_residences]).to include(
          "Number of old residences (5.0) and number of new residences "\
          "(94.0) don't add up to the total number of residences (100.0)."
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
  end # describe Dataset

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
    end # describe #new
  end # describe Dataset::Derived
end # Atlas
