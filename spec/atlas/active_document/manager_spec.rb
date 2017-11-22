require 'spec_helper'

module Atlas::ActiveDocument
  describe Manager do
    SomeDocument  = Atlas::SomeDocument
    FinalDocument = SomeDocument::FinalDocument

    let(:manager) { SomeDocument.manager }

    describe '#get' do
      it 'returns the matching document when given a symbol' do
        expect(manager.get(:foo)).to be
      end

      it 'returns the matching document when given a string' do
        expect(manager.get('foo')).to be
      end

      it 'returns nil when no matching document exists' do
        expect(manager.get(:no)).to_not be
      end

      it 'returns nil when given nil' do
        expect(manager.get(nil)).to_not be
      end

      context 'when the document has an illegal subclass' do
        before do
          File.write(SomeDocument.directory.join('a.nope.suffix'), '')
        end

        it 'raises an error' do
          expect { manager.get('a') }.
            to raise_error(Atlas::NoSuchDocumentClassError)
        end
      end
    end # get

    describe '#all' do
      it 'returns all the documents' do
        expect(manager.all).to have(5).documents
      end
    end # all

    describe '#key?' do
      it 'given a symbol, is true if a matching key exists' do
        expect(manager.key?(SomeDocument.all.first.key)).to be_true
      end

      it 'given a string, is true if a matching key exists' do
        expect(manager.key?(SomeDocument.all.first.key.to_s)).to be_true
      end

      it 'is false if a document with no matching key exists' do
        expect(manager.key?(:no)).to be_false
      end

      it 'is false if an unsaved document with a matching key exists' do
        SomeDocument.new(key: :hello)
        expect(manager.key?(:hello)).to be_false
      end
    end # key?

    describe '#clear!' do
      it 'removes the documents from the cache' do
        # First, we load a document to warm up the manager's cache, and
        # change the document key so that only a clear cache will reflect
        # this change.
        manager.get('foo').update_attributes!(key: 'new_key')

        manager.clear!

        expect(manager.get('foo')).to be_nil
        expect(manager.get('new_key')).to be
      end
    end # clear!

    describe 'when creating a new document' do
      let!(:document) { SomeDocument.new(key: 'something') }
      let(:manager)   { SomeDocument.manager }
      let(:result)    { manager.write(document) }

      it 'creates the new file' do
        expect { result }.
          to change { document.path.file? }.
          from(false).to(true)
      end

      it 'adds the document to the manager' do
        expect { result }.
          to change { manager.get(:something) }.
          from(nil).to(document)
      end

      it 'is returned when calling "all"' do
        expect { result }.
          to change { manager.all.include?(document) }.
          from(false).to(true)
      end

      it 'raises if a duplicate key already exists' do
        SomeDocument.new(key: document.key).save

        expect { result }.to raise_error(Atlas::DuplicateKeyError)
      end
    end # when creating a new document

    describe 'when creating a subclassed document' do
      let!(:document) { FinalDocument.new(key: 'something') }
      let(:manager)   { FinalDocument.manager }
      let(:result)    { manager.write(document) }

      it 'adds the document ot the topmost class manager' do
        expect { result }.
          to change { SomeDocument.manager.all.include?(document) }.
          from(false).to(true)
      end

      it 'can be retrieved by the subclass' do
        expect { result }.
          to change { manager.all.include?(document) }.
          from(false).to(true)
      end
    end # when creating a subclassed document

    describe 'when saving a document' do
      let!(:document) do
        SomeDocument.new(key: 'something', query: 'HELLO').tap do |doc|
          doc.save!
          doc.query = 'GOODBYE'
        end
      end

      let(:manager) { SomeDocument.manager }
      let(:result)  { manager.write(document) }

      it 'saves the changes' do
        expect { result }.to change { document.path.read }
      end
    end # when saving a document

    describe 'when renaming a document' do
      let!(:document) do
        SomeDocument.new(key: 'something').tap do |doc|
          doc.save!
          doc.key = :updated
        end
      end

      let(:manager) { SomeDocument.manager }
      let(:result)  { document.save! }

      it 'creates the new file' do
        new_path = SomeDocument.directory.join('updated.suffix')

        expect { result }.
          to change { new_path.file? }.
          from(false).to(true)
      end

      it 'raises if a duplicate key already exists' do
        SomeDocument.new(key: :updated).save

        expect { result }.to raise_error(Atlas::DuplicateKeyError)
      end

      it 'deletes the old file' do
        old_path = SomeDocument.directory.join('something.suffix')

        expect { result }.
          to change { old_path.file? }.
          from(true).to(false)
      end

      it 'is no longer reachable at the old key' do
        expect { result }.
          to change { manager.get(:something) }.
          from(document).to(nil)
      end

      it 'is reachable at the new key' do
        expect { result }.
          to change { manager.get(:updated) }.
          from(nil).to(document)
      end

      it 'is returned when calling "all"' do
        expect { result }.
          to_not change { manager.all.include?(document) }.
          from(true)
      end
    end # when creating a new document

    describe 'when deleting a file' do
      let!(:document) { SomeDocument.new(key: :original).tap(&:save!) }
      let(:manager)   { SomeDocument.manager }
      let(:result)    { manager.delete(document) }

      it 'deletes the file' do
        expect { result }.
          to change { document.path.file? }.
          from(true).to(false)
      end

      it 'removes the document from the manager' do
        expect { result }.
          to change { manager.get(:original) }.
          from(document).to(nil)
      end

      it 'is no longer returned when calling "all"' do
        expect { result }.
          to change { manager.all.include?(document) }.
          from(true).to(false)
      end
    end # when deleting a file

    describe 'when deleting a file path' do
      let!(:document) { SomeDocument.new(key: :original).tap(&:save!) }
      let(:manager)   { SomeDocument.manager }
      let(:result)    { manager.delete_path(document.path) }

      it 'deletes the file' do
        expect { result }.
          to change { document.path.file? }.
          from(true).to(false)
      end

      it 'removes the document from the manager' do
        expect { result }.
          to change { manager.get(:original) }.
          from(document).to(nil)
      end

      it 'is no longer returned when calling "all"' do
        expect { result }.
          to change { manager.all.include?(document) }.
          from(true).to(false)
      end
    end # when deleting a file path

    describe 'with an unparseable document' do
      before do
        content = <<-EOF.strip_heredoc
          - up     = down
          - leet   = 1337

          WTF
        EOF

        File.write(SomeDocument.directory.join('abc.suffix'), content)
      end

      it 'raises an error' do
        expect { SomeDocument.find(:abc) }.to raise_error(Atlas::ParserError)
      end

      it 'includes the filename in the message' do
        expect { SomeDocument.find(:abc) }.to raise_error(/abc\.suffix/)
      end
    end # with an unparseable document

    describe 'with a containing invalid content' do
      before do
        content = <<-EOF.strip_heredoc
          - up^    = down
          - leet   = 1337
        EOF

        File.write(SomeDocument.directory.join('abc.suffix'), content)
      end

      it 'raises an error' do
        expect { SomeDocument.find(:abc) }.
          to raise_error(Atlas::CannotParseError)
      end

      it 'includes the filename in the message' do
        expect { SomeDocument.find(:abc) }.to raise_error(/abc\.suffix/)
      end
    end # with a containing invalid content


    context 'saving an document whose to_hash contains non-attribute keys' do
      let(:klass) do
        Class.new(SomeDocument) do
          attribute :nested, self

          def self.name
            'WithNonAttribute'
          end

          def to_hash(*)
            super.merge(nope: 1)
          end
        end
      end

      context 'with a simple document' do
        let(:document) { klass.new(key: 'with_nonattr', unit: '%') }
        before { document.save! }

        it 'does not persist the non-attribute' do
          expect(document.path.read).to_not include('- nope =')
        end

        it 'does persists attributes' do
          expect(document.path.read).to include('- unit = %')
        end
      end

      context 'with a nested attribute, containing non-attribute keys' do
        let(:document) do
          klass.new(key: 'non_attr', unit: '%', nested: klass.new(unit: '#'))
        end

        before { document.save! }

        it 'does not persist the non-attribute' do
          expect(document.path.read).to_not include('- nope =')
        end

        it 'does not persist the nested attribute' do
          expect(document.path.read).to include('- nested.unit =')
        end

        it 'does not persist the nested non-attribute' do
          expect(document.path.read).to_not include('- nested.nope =')
        end
      end
    end # saving an document whose to_hash contains non-attribute keys
  end # Manager
end # Atlas::ActiveDocument
