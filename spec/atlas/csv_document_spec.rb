require 'spec_helper'

module Atlas
  describe CSVDocument do
    let(:doc) do
      path = Atlas.data_dir.join('truth.csv')

      path.open('w') do |f|
        f.puts(<<-EOF.lines.map(&:strip).join("\n"))
          -,yes,no,maybe possibly
          yes,1,0,1
          no,0,0,0
          maybe possibly,1,0,0.5
          oh_%^&/_he_said,-1,-1,-1
          blank,,
        EOF
      end

      CSVDocument.new(path.to_s)
    end

    it 'raises when the file does not exist' do
      expect { CSVDocument.new('no') }.to raise_error(/no such file/i)
    end

    it 'raises when a header cell contains no value' do
      path = Atlas.data_dir.join('blank.csv')
      path.open('w') { |f| f.puts(",yes\nyes,1") }

      expect { CSVDocument.new(path.to_s) }.
        to raise_error(BlankCSVHeaderError)
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

      it 'does not raise an error if a cell is blank' do
        expect { doc.get('blank', 'no') }.to_not raise_error
      end

      it 'does not raise an error if the column is named by its index' do
        expect { doc.get('blank', 1) }.to_not raise_error
      end
    end # get
  end # CSVDocument

  describe CSVDocument::OneDimensional do
    let(:doc) do
      path = Atlas.data_dir.join('carriers.csv')

      path.open('w') do |f|
        f.puts(<<-EOF.lines.map(&:strip).join("\n"))
          carrier,share,elec
          gas,0.3,no
          electricity,0.7,yes
        EOF
      end

      CSVDocument::OneDimensional.new(path.to_s)
    end

    describe '#get' do
      it 'returns the value of a valid row key' do
        expect(doc.get(:gas)).to eq(0.3)
      end

      it 'does not get the value of a header row' do
        expect { doc.get(:carrier) }.to raise_error(UnknownCSVRowError)
      end
    end # get
  end # CSVDocument::OneDimensional

  describe CSVDocument, '.curve' do
    context' with a simple list of values' do
      let(:doc) do
        path = Atlas.data_dir.join('curve.csv')

        path.open('w') do |f|
          f.puts(<<-EOF.lines.map(&:strip).join("\n"))
            0.0
            0.2
            0.3
          EOF
        end

        CSVDocument.curve(path.to_s)
      end

      it 'is an array' do
        expect(doc).to be_a(Array)
      end

      it 'contains all the values' do
        expect(doc.to_a).to eq([0.0, 0.2, 0.3])
      end
    end # with a simple list of values

    context' with a lines ending in a comma' do
      let(:doc) do
        path = Atlas.data_dir.join('curve.csv')

        path.open('w') do |f|
          f.puts(<<-EOF.lines.map(&:strip).join("\n"))
            0.0,
            0.2,
            0.3,
          EOF
        end

        CSVDocument.curve(path.to_s)
      end

      it 'contains all the values' do
        expect(doc.to_a).to eq([0.0, 0.2, 0.3])
      end
    end # with a lines ending in a comma

    context' with an empty file' do
      let(:doc) do
        path = Atlas.data_dir.join('curve.csv')
        path.open('w') { |f| f.puts('') }

        CSVDocument.curve(path.to_s)
      end

      it 'has no values' do
        expect(doc.to_a).to eq([])#be_empty
      end
    end # with a lines ending in a comma
  end # CSVDocument.curve
end # Atlas
