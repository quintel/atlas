require 'spec_helper'

module Atlas
  describe CSVDocument do
    let(:doc) do
      path = Atlas.data_dir.join('truth.csv')

      path.open('w') do |f|
        f.puts(<<-CSV.lines.map(&:strip).join("\n"))
          -,yes,no,maybe possibly
          yes,1,0,1
          no,0,0,0
          maybe possibly,1,0,0.5
          oh_%^&/_he_said,-1,-1,-1
          blank,,
        CSV
      end

      described_class.read(path.to_s)
    end

    describe '.read' do
      it 'raises when the file does not exist' do
        expect { described_class.read('no') }.to raise_error(/no such file/i)
      end

      it 'raises when a header cell contains no value' do
        path = Atlas.data_dir.join('blank.csv')
        path.open('w') { |f| f.puts(",yes\nyes,1") }

        expect { described_class.read(path.to_s) }
          .to raise_error(BlankCSVHeaderError)
      end
    end

    describe '.empty' do
      context 'with specified headers' do
        let(:headers) { %i[yes no maybe] }
        let(:path) { Atlas.data_dir.join('new.csv') }
        let(:doc) { described_class.empty(headers, path) }

        it 'does not save the new file to disk' do
          expect(File.exist?(doc.path)).to be(false)
        end

        it 'raises when the file already exists' do
          doc.save!
          expect { described_class.empty(%i[hello world], path.to_s) }
            .to raise_error(ExistingCSVHeaderError)
        end

        it 'sets the headers / column_keys' do
          expect(doc.column_keys).to eq(headers)
        end
      end
    end

    describe '#get' do
      it 'fetches values identified by row and column' do
        expect(doc.get('yes', 'no')).to be(0.0)
      end

      it 'fetches values when the row has a space' do
        expect(doc.get('maybe possibly', 'yes')).to be(1.0)
      end

      it 'fetches values when the column has a space' do
        expect(doc.get('no', 'maybe possibly')).to be(0.0)
      end

      it 'accepts underscores in place of spaces' do
        expect(doc.get('maybe_possibly', 'no')).to be(0.0)
      end

      it 'accepts any case' do
        expect(doc.get('Yes', 'yES')).to be(1.0)
      end

      it 'finds long names with special characters' do
        expect(doc.get('oh_he_said', 'yes')).to be(-1.0)
      end

      it 'finds column headers with special characters' do
        expect(doc.get('yes', 'maybe (possibly)')).to be(1.0)
      end

      it 'does not complain about trailing spaces' do
        expect(doc.get('yes ', ' yes')).to be(1.0)
      end

      it 'raises when no such row exists' do
        expect { doc.get('foo', 'yes') }.to raise_error(UnknownCSVRowError)
      end

      it 'raises an error when column header is not known' do
        expect { doc.get('yes', 'nope') }.to raise_error(UnknownCSVCellError)
      end

      it 'does not raise an error if a cell is blank' do
        expect { doc.get('blank', 'no') }.not_to raise_error
      end

      it 'does not raise an error if the column is named by its index' do
        expect { doc.get('blank', 1) }.not_to raise_error
      end
    end

    describe '#set' do
      it 'sets a given value for given row and column' do
        expect { doc.set('yes', 'no', 42) }.to change { doc.get('yes', 'no') }.from(0).to(42)
      end

      it 'creates non-existing rows on-the-fly' do
        expect { doc.get('foo bar', 'yes') }.to raise_error(UnknownCSVRowError)
        doc.set('foo bar', 'yes', 21)
        expect(doc.get('foo bar', 'yes')).to be(21)
      end

      it 'raises an error when column header is not known' do
        expect { doc.set('yes', 'nope', 99) }.to raise_error(UnknownCSVCellError)
      end
    end

    describe '#save!' do
      it 'saves the CSVDocument content to disk' do
        doc.set('yes', 'no', 42.0)
        doc.save!

        expect(File.readlines(doc.path).map(&:strip)).to eq(
          <<-EOF.lines.map(&:strip))
            "",yes,no,maybe_possibly
            yes,1.0,42.0,1.0
            no,0.0,0.0,0.0
            maybe possibly,1.0,0.0,0.5
            oh_%^&/_he_said,-1.0,-1.0,-1.0
            blank,,,
          EOF
      end

      context 'when the file did not exist before' do
        let(:doc) do
          described_class.empty(
            ['yes', 'no', 'maybe baby'],
            Atlas.data_dir.join('doesnotexistbefore.csv')
          )
        end

        it 'creates a new csv file' do
          doc.save!
          expect(File.file?(doc.path)).to be(true)
        end

        it 'creates a normalized header row in the csv file' do
          doc.save!
          expect(File.readlines(doc.path).first.strip).to eq('yes,no,maybe_baby')
        end
      end

      context 'when the CSV document is a symlink' do
        let(:link_path) { Atlas.data_dir.join('symlink.csv') }
        let(:source_path) { Atlas.data_dir.join('source.csv') }

        let(:doc) do
          source_path.open('w') { |f| f.puts(original_content) }
          described_class.read(link_path)
        end

        let(:original_content) do
          <<-CSV.lines.map(&:strip).join("\n")
            key,attribute
            one,1

          CSV
        end

        let(:new_content) do
          <<-CSV.lines.map(&:strip).join("\n")
            key,attribute
            one,2

          CSV
        end

        before do
          FileUtils.ln_s(source_path, link_path)
          doc.set('one', 'attribute', 2)
        end

        describe 'with no follow_link value' do
          before { doc.save! }

          it 'saves the file at the symlink location' do
            expect(source_path.read).to eq(new_content)
          end

          it 'retains the symlink' do
            expect(link_path).to be_symlink
          end
        end

        describe 'with follow_link: true' do
          before { doc.save!(follow_link: true) }

          it 'saves the file at the symlink location' do
            expect(source_path.read).to eq(new_content)
          end

          it 'retains the symlink' do
            expect(link_path).to be_symlink
          end
        end

        describe 'with follow_link: false' do
          before { doc.save!(follow_link: false) }

          it 'saves the file at the initialzied path' do
            expect(link_path.read).to eq(new_content)
          end

          it 'removes the symlink' do
            expect(link_path).not_to be_symlink
          end

          it 'does not change the original file' do
            expect(source_path.read).to eq(original_content)
          end
        end
      end
    end
  end

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

      described_class.read(path.to_s)
    end

    describe '#get' do
      it 'returns the value of a valid row key' do
        expect(doc.get(:gas)).to be(0.3)
      end

      it 'does not get the value of a header row' do
        expect { doc.get(:carrier) }.to raise_error(UnknownCSVRowError)
      end
    end
  end

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
    end

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
    end

    context' with an empty file' do
      let(:doc) do
        path = Atlas.data_dir.join('curve.csv')
        path.open('w') { |f| f.puts('') }

        CSVDocument.curve(path.to_s)
      end

      it 'has no values' do
        expect(doc.to_a).to eq([])#be_empty
      end
    end
  end
end
