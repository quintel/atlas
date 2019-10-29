require 'spec_helper'

module Atlas

describe SomeDocument do
  let(:some_document) { some_document = SomeDocument.find('foo') }

  describe 'new' do
    context 'given no key or path' do
      it 'does not raise an error' do
        expect { SomeDocument.new({}) }.not_to raise_error
      end
    end

    context 'given a dumb key' do
      it 'creates a new document' do
        expect(SomeDocument.new(key: 'key')).to be_a(SomeDocument)
      end

      it 'sets the key (as a symbol)' do
        expect(SomeDocument.new(key: 'key').key).to eq(:key)
      end

      it 'sets the key when the hash keys are strings' do
        expect(SomeDocument.new('key' => 'key').key).to eq(:key)
      end

      it 'sets no subdirectory' do
        expect(SomeDocument.new(path: 'key').subdirectory).to be_nil
      end

      xit 'raises and error when the key already exists' do
        expect(-> { SomeDocument.new(key: 'foo') } ).to \
          raise_error DuplicateKeyError
      end
    end

    context 'given a path' do
      it 'creates a new document' do
        some_document = SomeDocument.new(path: 'my_map1/new')
        expect(some_document.save!).to be(true)
        expect(some_document.key).to eq(:new)
      end

      it 'sets the key (as a symbol)' do
        expect(SomeDocument.new(path: 'a/b/thing').key).to eq(:thing)
      end

      it 'sets the key when the hash keys are strings' do
        expect(SomeDocument.new('path' => 'a/b/thing').key).to eq(:thing)
      end

      it 'saves in that folder' do
        some_document = SomeDocument.new(path: 'my_map1/new')
        expect(some_document.key).to eq(:new)
        expect(some_document.path.to_s).to match /my_map1\/new/
      end

      it 'sets no subdirectory' do
        document = SomeDocument.new(path: 'my_map1/new')
        expect(document.subdirectory).to eq('my_map1')
      end

      xit 'raises and error when the key already exists' do
        SomeDocument.new(path: 'my_map1/new').save!

        expect(-> { SomeDocument.new(path: 'my_map2/new') } ).to \
          raise_error DuplicateKeyError
      end
    end
  end

  describe 'queries' do

    it 'remembers them' do
      document = SomeDocument.new(key: 'a', queries: { foo: 'bar' })
      expect(document.queries).to eq({ foo: 'bar' })
    end

  end

  describe 'to_hash' do
    it 'is empty when no attributes have been set' do
      expect(SomeDocument.new(key: 'a').to_hash).to eq({})
    end

    it 'contains attributes set by the user' do
      document = SomeDocument.new(key: 'a', unit: '%', comments: 'Mine')
      hash     = document.to_hash

      expect(hash).to include(unit: '%')
      expect(hash).to include(comments: 'Mine')
    end

    it 'does not contain queries' do
      document = SomeDocument.new(key: 'a', queries: { foo: 'bar' })

      expect(document.to_hash).not_to have_key(:queries)
    end

    it 'omits attributes which have no value' do
      document = SomeDocument.new(key: 'a', unit: '%')
      hash     = document.to_hash

      expect(hash).not_to have_key(:query)
      expect(hash).not_to have_key(:comments)
    end

    it 'includes file comments' do
      document = SomeDocument.new(key: 'a', comments: 'okay')
      hash     = document.to_hash

      expect(hash).to include(comments: 'okay')
    end
  end

  describe "find" do
    it "should load a some_document from file" do
      expect(some_document.key).to eq(:foo)
      expect(some_document.path.to_s).to include(some_document.key.to_s)
      expect(some_document.comments.size).to be > 0
      expect(some_document.comments).to include "MECE" #testing some words
      expect(some_document.comments).to include "graph." #testing some words
      expect(some_document.unit).to eq('kg')
      expect(some_document.queries).to eq( { demand: "SUM(\n  Q(co2_emissions_of_final_demand_excluding_imported_electricity),\n  Q(co2_emissions_of_imported_electricity)\n)" })
    end

    it "should find by Symbol" do
      some_document = Atlas::SomeDocument.find(:foo)
      expect(some_document.key).to eq(:foo)
    end

    it "should find by String" do
      some_document = Atlas::SomeDocument.find('foo')
      expect(some_document.key).to eq(:foo)
    end

    it "loads a document from a subfolder" do
      another_document = Atlas::SomeDocument.find(:bar)
      expect(another_document).not_to be_nil
    end

    it 'loads subclassed documents' do
      document = SomeDocument::OtherDocument.new(key: 'other')
      document.save!

      expect(SomeDocument.find('other')).to be
    end

    it 'raises an error if no document exists' do
      expect { SomeDocument.find('omg') }.
        to raise_error(DocumentNotFoundError)
    end

    it 'raises an error if the document belongs to a superclass' do
      SomeDocument::OtherDocument.new(key: 'other').save!

      expect { SomeDocument::FinalDocument.find('other') }.
        to raise_error(DocumentNotFoundError)
    end

  end

  describe '.exists?' do
    it 'returns true when a matching document exists' do
      expect(Atlas::SomeDocument.exists?(:foo)).to be(true)
    end

    it 'returns false when no matching document exists' do
      expect(Atlas::SomeDocument.exists?(:nope)).to be(false)
    end

    it 'returns false when no SAVED document exists' do
      Atlas::SomeDocument.new(key: :nope)
      expect(Atlas::SomeDocument.exists?(:nope)).to be(false)
    end
  end

  describe '.create' do
    context 'when the document is valid' do
      let(:document) do
        SomeDocument.create(key: :okay, unit: '%',
                            query: 'A', do_validation: true)
      end

      it 'sets the given attributes' do
        expect(document.key).to eq(:okay)
        expect(document.unit).to eq('%')
        expect(document.query).to eq('A')
      end

      it 'saves the document' do
        expect(document.path.file?).to be(true)
      end

      it 'has no errors' do
        expect(document.errors).to be_empty
      end
    end

    context 'when the document is invalid' do
      let(:document) do
        SomeDocument.create(key: :okay, unit: '%', do_validation: true)
      end

      it 'sets the given attributes' do
        expect(document.key).to eq(:okay)
        expect(document.unit).to eq('%')
        expect(document.query).to be_nil
      end

      it 'does not save the document' do
        expect(document.path.file?).to be(false)
      end

      it 'has an error' do
        expect(document.errors).not_to be_empty
      end
    end
  end

  describe '.create!' do
    context 'when the document is valid' do
      let(:document) do
        SomeDocument.create!(key: :okay, unit: '%',
                             query: 'A', do_validation: true)
      end

      it 'sets the given attributes' do
        expect(document.key).to eq(:okay)
        expect(document.unit).to eq('%')
        expect(document.query).to eq('A')
      end

      it 'saves the document' do
        expect(document.path.file?).to be(true)
      end

      it 'has no errors' do
        expect(document.errors).to be_empty
      end
    end

    context 'when the document is invalid' do
      let(:document) do
        SomeDocument.create!(key: :okay, unit: '%', do_validation: true)
      end

      it 'sets the given attributes' do
        expect { document }.to raise_error(Atlas::InvalidDocumentError)
      end
    end
  end

  describe "key" do
    it "returns just the key part" do
      expect(some_document.key).to eq(:foo)
    end
  end

  describe 'key=' do
    context 'setting the key to nil' do
      let(:doc) { SomeDocument.new(key: 'key') }

      it 'raises InvalidKeyError' do
        expect { doc.key = nil }.to raise_error(InvalidKeyError)
      end
    end

    context 'setting an empty key' do
      let(:doc) { SomeDocument.new(key: 'key') }

      it 'raises InvalidKeyError' do
        expect { doc.key = '' }.to raise_error(InvalidKeyError)
      end
    end

    context 'on an existing document' do
      let(:doc) { SomeDocument.create!(key: 'hello') }

      it 'remains persisted' do
        expect { doc.key = 'new_name' }.not_to change { doc.persisted? }
      end
    end

    context 'when the document is at the class DIRECTORY root' do
      let(:doc) { SomeDocument.new(key: 'key') }
      before    { doc.key = 'new' }

      it 'changes the document key' do
        expect(doc.key).to eq(:new)
      end

      it 'puts the file at the DIRECTORY root' do
        expect(doc.path).
          to eq(SomeDocument.directory.join('new.suffix'))
      end
    end

    context 'when the document path includes a subdirectory' do
      let(:doc) { SomeDocument.new(path: 'dir/key') }
      before    { doc.key = 'new' }

      it 'changes the document key' do
        expect(doc.key).to eq(:new)
      end

      it 'puts the file in the subdirectory' do
        expect(doc.path).
          to eq(SomeDocument.directory.join('dir/new.suffix'))
      end
    end

    context 'when the document name contains the suffix substring' do
      let(:doc) { SomeDocument.new(path: 'suffix.suffix') }
      before    { doc.key = 'new' }

      it 'changes the document key' do
        expect(doc.key).to eq(:new)
      end

      it 'puts the file at the DIRECTORY root' do
        # Asserts that the suffix is not altered.
        expect(doc.path).to eq(SomeDocument.directory.join('new.suffix'))
      end
    end

    context 'when the document is a subclass' do
      let(:doc) { SomeDocument::FinalDocument.new(path: 'okay') }
      before    { doc.key = 'new' }

      it 'changes the document key' do
        expect(doc.key).to eq(:new)
      end

      it 'retains the subclass string in the filename' do
        expect(doc.path.to_s).to include('.final_document')
      end
    end
  end

  context '#path=' do
    context 'on a "base" class instance' do
      let(:document) { SomeDocument.new(path: 'abc') }

      it 'sets the new key' do
        document.path = 'def'
        expect(document.key).to eq(:def)
      end

      it 'ignores new subclass prefixes' do
        document.path = 'def.final_document.ad'
        expect(document.path).to eq(SomeDocument.directory.join('def.suffix'))
      end

      it 'ignores new file extensions' do
        document.path = 'def.omg'
        expect(document.path.to_s).to match(%r{/def\.suffix$})
      end

      it 'sets new subdirectories' do
        document.path = 'yes/no/omg'
        expect(document.subdirectory).to eq('yes/no')
      end

      it 'raises an error if the path is above the document root' do
        expect { document.path = '../omg' }.
          to raise_error(IllegalDirectoryError)
      end
    end

    context 'with an absolute path' do
      let(:document) { SomeDocument.new(path: 'abc') }

      it 'sets legal paths' do
        document.path = document.directory.join('efg')
        expect(document.path).to eq(document.directory.join('efg.suffix'))
      end

      it 'raises an error if the path is above the document root' do
        expect { document.path = document.directory.dirname.join('efg') }.
          to raise_error(IllegalDirectoryError)
      end
    end

    context 'on a subclass instance' do
      let(:document) { SomeDocument::FinalDocument.new(key: 'abc') }

      it 'retains the subclass prefix' do
        document.path = 'abc.other_document.suffix'

        expect(document.path.to_s).to     include('final_document')
        expect(document.path.to_s).not_to include('other_document')
      end
    end
  end

  describe 'ns' do
    it 'returns nil when the document is in the root' do
      expect(SomeDocument.new(path: 'abc').ns).to be_nil
    end

    it 'returns "one" when the document is in a "one" subdirectory' do
      expect(SomeDocument.new(path: 'one/abc').ns).to eq('one')
    end

    it 'returns "one.two" when the document is in "one/two" subdirectory' do
      expect(SomeDocument.new(path: 'one/two/abc').ns).to eq('one.two')
    end
  end

  describe 'ns=' do
    let(:document) { SomeDocument.new(path: 'one/abc') }
    let(:dir)      { SomeDocument.directory }

    context 'given nil' do
      before { document.ns = nil }

      it { expect(document.ns).to be_nil }
      it { expect(document.path).to eq(dir.join('abc.suffix')) }
    end

    context 'given ""' do
      before { document.ns = '' }

      it { expect(document.ns).to be_nil }
      it { expect(document.path).to eq(dir.join('abc.suffix')) }
    end

    context 'given "two"' do
      before { document.ns = 'two' }

      it { expect(document.ns).to eq('two') }
      it { expect(document.path).to eq(dir.join('two/abc.suffix')) }
    end

    context 'given "two.three"' do
      before { document.ns = 'two.three' }

      it { expect(document.ns).to eq('two.three') }
      it { expect(document.path).to eq(dir.join('two/three/abc.suffix')) }
    end

    context 'given "two/three"' do
      before { document.ns = 'two/three' }

      it { expect(document.ns).to eq('two.three') }
      it { expect(document.path).to eq(dir.join('two/three/abc.suffix')) }
    end
  end

  describe 'ns?' do
    let(:document) { SomeDocument.new(key: 'abc', ns: 'one.two.three') }

    it 'matches when given the full namespace' do
      expect(document.ns?('one.two.three')).to be(true)
    end

    it 'matches when given a partial namespace' do
      expect(document.ns?('one.two')).to be(true)
    end

    it 'does not match when given a non-matching namespace' do
      expect(document.ns?('four')).to be(false)
    end

    it 'does not match when given a non-matching final segment' do
      expect(document.ns?('one.two.four')).to be(false)
    end
  end

  describe "path" do
    it "should change when the key has changed" do
      some_document.key = :total_co2_emitted
      expect(some_document.key).to eq(:total_co2_emitted)
      expect(some_document.path.to_s).to include "total_co2_emitted"
    end
  end

  describe 'valid?' do
    let(:document) do
      SomeDocument.new(key: 'key').tap do |doc|
        doc.do_validation = true
      end
    end

    it 'is false if validation fails' do
      document.query = nil
      expect(document).not_to be_valid
    end

    it 'is true if validation succeeds' do
      document.query = 'MAX(0, 0)'
      expect(document).to be_valid
    end
  end

  describe "save!" do
    context 'new file' do
      it 'writes to disk' do
        some_document = SomeDocument.new(key: 'the_king_of_pop')
        expect(some_document.save!).to be(true)
      end

      it 'becomes persisted' do
        some_document = SomeDocument.new(key: 'the_king_of_pop')

        expect { some_document.save! }
          .to change { some_document.persisted? }
          .from(false).to(true)
      end

      it 'ceases to be a new record' do
        some_document = SomeDocument.new(key: 'the_king_of_pop')

        expect { some_document.save! }
          .to change { some_document.new_record? }
          .from(true).to(false)
      end
    end

    context 'when nothing changed' do
      it "does not write to disk" do
        cache = some_document.path.read
        some_document.save!
        expect(cache).to eq(some_document.path.read)
      end
    end

    context 'when validation fails' do
      let(:result) do
        some_document.do_validation = true
        some_document.update_attributes!(comments: 'Archer', query: nil)
      end

      it 'does not save the file' do
        original_contents = some_document.path.read
        (result rescue nil)
        expect(some_document.path.read).to eq(original_contents)
      end

      it 'raises an exception' do
        expect { result }.to raise_error(InvalidDocumentError)
      end
    end

    context 'when the key changed' do
      it "should delete the old file" do
        old_path = some_document.path
        some_document.key = "foo2"
        some_document.save!
        expect { old_path.read }.to raise_error(Errno::ENOENT)
      end

      it "should create a new file" do
        some_document.key = "foo2"
        some_document.save!
        expect { some_document.path.read }.not_to raise_error
      end

      it 'remains persisted' do
        expect do
          some_document.key = 'foo2'
          some_document.save!
        end.not_to change { some_document.persisted? }.from(true)
      end

      it 'works when the document is new' do
        document = SomeDocument.new(key: 'yes')
        document.key = 'no'

        expect { document.save! }.not_to raise_error
      end

      it 'no longer finds the old document' do
        some_document.update_attributes!(key: :foo2)

        expect { SomeDocument.find(:foo) }.
          to raise_error(Atlas::DocumentNotFoundError)
      end

      it 'finds the new document' do
        some_document.update_attributes!(key: :foo2)
        expect(SomeDocument.find(:foo2)).to eq(some_document)
      end

      it 'is considered persisted' do
        some_document.update_attributes!(key: :foo2)
        expect(some_document).to be_persisted
      end

      it 'is not a new record' do
        some_document.update_attributes!(key: :foo2)
        expect(some_document).not_to be_new_record
      end

      context 'when another object with that key already exists' do

        it 'raises error' do
          pending 'Pending re-introduction of duplicate-key check'

          # Was temporarily removed due to stack overflows with the
          # ETengine specs.
          expect(-> { some_document.key = 'bar'}).
            to raise_error(DuplicateKeyError)
        end

      end

    end

  end

  describe '#update_attributes!' do
    let(:document) { SomeDocument.find('foo') }

    context 'when successful' do
      let(:result) do
        document.update_attributes!(comments: 'Archer', query: '*')
      end

      it 'returns true' do
        expect(result).to be(true)
      end

      it 'updates given attributes' do
        expect { result }.to change {
          document.attributes.values_at(:comments, :query)
        }.to(%w( Archer * ))
      end

      it 'leaves omitted attributes alone' do
        expect { result }.not_to change(document, :unit)
      end
    end

    context 'when validation fails' do
      let(:result) do
        document.do_validation = true
        document.update_attributes!(comments: 'Archer', query: nil)
      end

      it 'updates given attributes' do
        expect { (result rescue nil) }.to change {
          document.attributes.values_at(:comments, :query)
        }.to(['Archer', nil])
      end

      it 'raises an error' do
        expect { result }.to raise_error(Atlas::InvalidDocumentError, /Query/)
      end
    end
  end

  describe '#all' do
    context 'on a "leaf" class' do
      it 'returns only members of that class' do
        expect(SomeDocument::FinalDocument.all.length).to eq(1)
      end
    end

    context 'on a "branch" class' do
      it "returns members of that class, and it's subclasses" do
        classes = SomeDocument::OtherDocument.all.map(&:class).uniq

        expect(classes.length).to eq(2)

        expect(classes).to include(SomeDocument::OtherDocument)
        expect(classes).to include(SomeDocument::FinalDocument)
      end
    end
  end

  describe 'changing the key on subclassed documents' do
    let(:doc) do
      SomeDocument::OtherDocument.new(path: 'fd.other_document.suffix')
    end

    before { doc.key = 'pd' }

    it 'retains the extension and subclass' do
      expect(doc.key).to eq(:pd)
    end

    it 'retains the subclass suffix' do
      expect(doc.path.basename.to_s).
        to eq([
          doc.key,
          doc.class.subclass_suffix,
          doc.class::FILE_SUFFIX].join('.'))
    end
  end

  describe 'destroy!' do
    it 'deletes the file' do
      path = some_document.path
      some_document.destroy!
      expect(path.exist?).to be(false)
    end

    it 'is no longer persited' do
      expect { some_document.destroy! }
        .to change { some_document.persisted? }
        .from(true).to(false)
    end

    it 'becomes a new record' do
      expect { some_document.destroy! }
        .to change { some_document.new_record? }
        .from(false).to(true)
    end
  end

  describe 'inspect' do

    it 'should contain the key' do
      expect(some_document.to_s).to include(some_document.key.to_s)
    end

    it 'should contain the class name' do
      expect(some_document.to_s).to include(some_document.class.to_s)
    end

  end

  describe '#<=>' do
    let(:node) { Node.new(key: 'f') }

    it 'is -1 when the node has an "earlier" key' do
      expect(Node.new(key: 'a') <=> node).to eq(-1)
    end

    it 'is 0 when the node has an equal key' do
      expect(Node.new(key: 'f') <=> node).to eq(0)
    end

    it 'is 1 when the node has a "later" key' do
      expect(Node.new(key: 'z') <=> node).to eq(1)
    end
  end

  describe 'path normalization' do
    context 'given a path which includes the DIRECTORY' do
      let(:node) { SomeDocument.new(path: 'active_document/foo.suffix') }

      it 'the DIRECTORY still gets prepended' do
        expect(node.path).
          to eq(SomeDocument.directory.join('active_document/foo.suffix'))
      end
    end

    context 'given a path in a subdirectory' do
      let(:node) { SomeDocument.new(path: 'special/foo.suffix') }

      it 'does not change the given path' do
        expect(node.path).
          to eq(SomeDocument.directory.join('special/foo.suffix'))
      end
    end

    context 'given a path which contains a subdirectory and no key' do
      let(:node) { SomeDocument.new(path: 'special/foo') }

      it 'does not change the given path' do
        expect(node.path.sub_ext('')).
          to eq(SomeDocument.directory.join('special/foo'))
      end

      it 'adds the file extension' do
        expect(node.path.extname).to eq('.suffix')
      end
    end

    context 'given only a key' do
      let(:node) { SomeDocument.new(path: 'foo') }

      it 'adds the document directory' do
        expect(node.path.to_s).to match(%r{active_document/})
      end

      it 'adds the file extension' do
        expect(node.path.extname).to eq('.suffix')
      end

      it 'sets the filename to equal the key' do
        expect(node.path.basename.sub_ext('').to_s).to eq('foo')
      end
    end

    context 'given no key' do
      let(:node) { SomeDocument.new }

      it 'fails validation when saved' do
        node.valid?
        expect(node.errors[:key]).to include("can't be blank")
      end

      it 'does not save the document' do
        expect { node.save }.not_to change { node.path.file? }.from(false)
      end
    end

    context 'given an absolute path' do
      let(:node) { SomeDocument.new(path: '/tmp/foo') }

      it 'raises an error' do
        expect { node }.to raise_error(IllegalDirectoryError)
      end
    end
  end
end

end
