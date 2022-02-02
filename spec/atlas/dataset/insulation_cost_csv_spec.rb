# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlas::Dataset::InsulationCostCSV do
  describe 'with an upgrade cost CSV' do
    let(:doc) do
      path = Atlas.data_dir.join('truth.csv')

      path.open('w') do |f|
        f.puts(<<-CSV.lines.map(&:strip).join("\n"))
          present,0,1,2,3
          0,      0,10,20,30
          1,      -100,0,100,200
          2,      -2000,-1000,0,1000
          3,      -30000,-20000,-10000,0
        CSV
      end

      described_class.read(path.to_s)
    end

    context 'when querying the first row' do
      it 'may retrieve the 0 value with integer keys' do
        expect(doc.get(0, 0)).to eq(0)
      end

      it 'may retrieve the 1 value with integer keys' do
        expect(doc.get(0, 1)).to eq(10)
      end

      it 'may retrieve the 3 value with integer keys' do
        expect(doc.get(0, 3)).to eq(30)
      end

      it 'may retrieve the 2 value with string keys' do
        expect(doc.get('0', '2')).to eq(20)
      end

      it 'may retrieve the 2 value with symbol keys' do
        expect(doc.get(:'0', :'2')).to eq(20)
      end

      it 'may retrieve the 2 value with float keys' do
        expect(doc.get(0.0, 2.0)).to eq(20)
      end
    end

    context 'when querying the second row' do
      it 'may retrieve the 0 value' do
        expect(doc.get(1, 0)).to eq(-100)
      end

      it 'may retrieve the 1 value' do
        expect(doc.get(1, 1)).to eq(0)
      end

      it 'may retrieve the 3 value' do
        expect(doc.get(1, 3)).to eq(200)
      end
    end
  end

  describe 'with a new-build cost CSV' do
    let(:doc) do
      path = Atlas.data_dir.join('truth.csv')

      path.open('w') do |f|
        f.puts(<<-CSV.lines.map(&:strip).join("\n"))
          type,0,1,2,3
          apartment,1,2,3,4
          building,10,20,30,40
        CSV
      end

      described_class.read(path.to_s)
    end

    describe 'when querying the "apartment" row' do
      it 'may retrieve the 0 value with "apartment",0' do
        expect(doc.get('apartment', 0)).to eq(1)
      end

      it 'may retrieve the 0 value with "apartment","0"' do
        expect(doc.get('apartment', '0')).to eq(1)
      end

      it 'may retrieve the 0 value with :apartment,"0"' do
        expect(doc.get(:apartment, '0')).to eq(1)
      end

      it 'may retrieve the 0 value with :apartment,0.0' do
        expect(doc.get(:apartment, 0.0)).to eq(1)
      end

      it 'may retrieve the 1 value with "apartment",1' do
        expect(doc.get('apartment', 1)).to eq(2)
      end

      it 'may retrieve the 1 value with "apartment","1"' do
        expect(doc.get('apartment', '1')).to eq(2)
      end

      it 'raises an error when the column does not exist' do
        expect { doc.get('apartment', 40) }
          .to raise_error(Atlas::UnknownCSVCellError)
      end
    end

    describe 'when querying the "building" row' do
      it 'may retrieve the 0 value with "building",0' do
        expect(doc.get('building', 0)).to eq(10)
      end

      it 'may retrieve the 1 value with "building",1' do
        expect(doc.get('building', 1)).to eq(20)
      end
    end

    describe 'when querying a row which does not exist' do
      it 'raises an error' do
        expect { doc.get('bunker', 0) }
          .to raise_error(Atlas::UnknownCSVRowError)
      end
    end
  end
end
