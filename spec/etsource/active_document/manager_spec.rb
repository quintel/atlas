require 'spec_helper'

module ETSource::ActiveDocument
  describe Manager, :fixtures do
    SomeDocument = ETSource::SomeDocument

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
    end # when deleting a file path
  end # Manager
end # ETSource::IO
