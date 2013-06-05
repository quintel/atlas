require 'spec_helper'

module Tome::ActiveDocument
  describe Manager, :fixtures do
    SomeDocument  = Tome::SomeDocument
    FinalDocument = Tome::FinalDocument

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
    end # get

    describe '#all' do
      it 'returns all the documents' do
        expect(manager.all).to have(5).documents
      end
    end # all

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
  end # Manager
end # Tome::ActiveDocument
