require 'spec_helper'

module Atlas; describe Dataset, :fixtures do
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
      expect(dataset.key).to eql(:nl)
    end

    it "finds the UK dataset from file" do
      dataset = Dataset.find(:uk)
      expect(dataset).to be_a(Dataset)
      expect(dataset.key).to eql(:uk)
    end
  end # describe #load

  describe '#dataset_dir' do
    let(:dataset) { Dataset.new(key: :kr) }

    it 'includes the data directory' do
      expect(dataset.dataset_dir.to_s).to include(Atlas.data_dir.to_s)
    end

    it 'points to the datasets subdirectory' do
      expect(dataset.dataset_dir.to_s).to include('/datasets/')
    end

    it 'includes the dataset key' do
      expect(dataset.dataset_dir.to_s).to end_with('/kr')
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
    let(:curves)  { dataset.time_curve(:bio_residues) }

    it 'returns a CSV document' do
      expect(curves).to be_a(CSVDocument)
    end

    it 'sets the file path' do
      expect(curves.path.to_s).
        to end_with('nl/time_curves/bio_residues_time_curve.csv')
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
        expect(keys).to include(:bio_residues)
        expect(keys).to include(:coal)
      end
    end # when no curves have been loaded

    describe 'when a curve has already been loaded' do
      let!(:loaded) { dataset.time_curve(:bio_residues) }

      it 'loads all the time curves' do
        expect(dataset.time_curves).to have(2).csv_documents
      end

      it "reuses the already-loaded curve" do
        expect(dataset.time_curves.values).to include(loaded)
      end
    end # when a curves has already been loaded
  end # time_curves
end ; end
