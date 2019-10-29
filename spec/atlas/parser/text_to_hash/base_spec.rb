require 'spec_helper'

module Atlas::Parser::TextToHash
  describe Base do
    let(:base)    { Base.new }
    let(:content) { "# a\n# b\n- unit = kg\n~ demand =\n  SUM(1,2)" }

    describe '#new' do
      context 'when no content provided' do
        it 'contains no lines yet' do
          expect(base.lines).to be_empty
        end
      end

      context 'when content is provided' do
        it 'parses content' do
          base = Base.new(content)
          expect(base.lines[0].to_s).to eql '# a'
          expect(base.lines[1].to_s).to eql '# b'
          expect(base.lines[2].to_s).to eql '- unit = kg'
        end
      end
    end

    describe '#lines' do
      it 'can append lines' do
        line = Line.new('blah')
        expect(base.add_line(line)).to eql line
        expect(base.lines[0]).to eql line
      end
    end

    describe '#blocks' do
      it 'has content' do
        base = Base.new(content)
        expect(base.blocks.length).to eq(3)
      end
    end

    describe '#comments' do
      it 'contains the comments' do
        base = Base.new(content)
        expect(base.comments).to eql( "a\nb" )
      end

      it 'returns nil when there aint none' do
        base = Base.new('- unit = kg')
        expect(base.comments).to be_nil
      end
    end

    describe '#properties' do
      it 'contains only fixed' do
        base = Base.new(content)
        expect(base.properties).to eql({ unit: 'kg' })
      end

      it 'supports numbers' do
        base = Base.new('- foo = 123.4')
        expect(base.properties).to eql({ foo: 123.4 })
      end

      it 'returns nil when there aint none' do
        base = Base.new("~ demand =\n  SUM(1,2)")
        expect(base.properties).to eql({})
      end
    end

    describe '#dynamic_attributes' do
      it 'contains only dynamic ones' do
        base = Base.new(content)
        expect(base.queries).to eql({ demand: 'SUM(1,2)' })
      end

      it 'returns nil when there aint none' do
        base = Base.new("")
        expect(base.queries).to eql({})
      end
    end

    describe '#to_hash' do
      it 'has everything' do
        base = Base.new(content)
        hash = { comments: "a\nb",
                 unit:     "kg",
                 queries:  { demand: "SUM(1,2)" } }
        expect(base.to_hash).to eql hash
      end
    end
  end
end
