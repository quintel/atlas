require 'spec_helper'

module Tome; describe Dataset, :fixtures do
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

  describe '#path' do
    let(:dataset) { Dataset.new(key: :kr) }

    it 'includes the data directory' do
      expect(dataset.path.to_s).to include(Tome.data_dir.to_s)
    end

    it 'points to the datasets subdirectory' do
      expect(dataset.path.to_s).to include('/datasets/')
    end

    it 'includes the dataset key' do
      expect(dataset.path.to_s).to end_with('/kr')
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

  describe '#chps' do
    let(:dataset) { Dataset.find(:nl) }
    let(:chps)    { dataset.chps }

    it 'returns a CSV document' do
      expect(chps).to be_a(CSVDocument)
    end

    it 'sets the file path' do
      expect(chps.path.to_s).to end_with('nl/chp.csv')
    end

    it 'raises an error when no shares data exists' do
      dataset.chps.path.delete

      # We need to clear the Manager cache to force a new dataset instance
      # to be created.
      Dataset.manager.clear!

      expect { Dataset.find(:nl).chps }.to raise_error(Errno::ENOENT)
    end
  end # shares
end ; end
