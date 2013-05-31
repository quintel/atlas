require 'spec_helper'

module Tome
  describe CSVDocument, :fixtures do
    let(:doc) do
      path = Tome.data_dir.join('truth.csv')

      path.open('w') do |f|
        f.puts(<<-EOF.lines.map(&:strip).join("\n"))
          -,yes,no,maybe possibly
          yes,1,0,1
          no,0,0,0
          maybe possibly,1,0,0.5
          oh_%^&/_he_said,-1,-1,-1
        EOF
      end

      CSVDocument.new(path.to_s)
    end

    it 'raises when the file does not exist' do
      expect { CSVDocument.new('no') }.to raise_error(/no such file/i)
    end

    describe '#get' do
      it 'fetches values identified by row and column' do
        expect(doc.get('yes', 'no')).to eq(0)
      end

      it 'fetches values when the row has a space' do
        expect(doc.get('maybe possibly', 'yes')).to eq(1)
      end

      it 'fetches values when the column has a space' do
        expect(doc.get('no', 'maybe possibly')).to eq(0)
      end

      it 'accepts underscores in place of spaces' do
        expect(doc.get('maybe_possibly', 'no')).to eq(0)
      end

      it 'accepts any case' do
        expect(doc.get('Yes', 'yES')).to eq(1)
      end

      it 'finds long names with special characters' do
        expect(doc.get('oh_he_said', 'yes')).to eq(-1)
      end

      it 'finds special character carriers with special characters' do
        expect(doc.get('yes', 'maybe (possibly)')).to be(1)
      end

      it 'does not complain about trailing spaces' do
        expect(doc.get('yes ', ' yes')).to be(1)
      end

      it 'raises when no such row exists' do
        expect { doc.get('foo', 'yes') }.to raise_error(UnknownCSVRowError)
      end

      it 'raises an error when carrier is not known' do
        expect { doc.get('yes', 'nope') }.to raise_error(UnknownCSVCellError)
      end
    end # get
  end # CSVDocucmnet
end # Tome
