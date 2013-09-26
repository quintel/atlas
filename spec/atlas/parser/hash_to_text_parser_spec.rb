require 'spec_helper'

module Atlas

  describe HashToTextParser do

    describe 'new' do
      it "should create a new parser" do
        expect(-> { HashToTextParser.new({}) }).to_not raise_error
      end
      it "should raise an ArgumentError when called with no Hash" do
        expect(-> { HashToTextParser.new() }).to raise_error ArgumentError
        expect(-> { HashToTextParser.new(nil) }).to raise_error ArgumentError
        expect(-> { HashToTextParser.new("string") }).to raise_error ArgumentError
      end
    end

    describe "to_text" do

      it "parses one attribute" do
        p = HashToTextParser.new({foo: 'bar'})
        expect(p.to_text).to eql "- foo = bar"
      end

      it "parses two attributes" do
        p = HashToTextParser.new({foo: 'bar', fool: 'bars'})
        expect(p.to_text).to eql "- foo = bar\n- fool = bars"
      end

      it 'parses attributes as an Array' do
        p = HashToTextParser.new({array: ["a","b"]})
        expect(p.to_text).to eql "- array = [a, b]"
      end

      it 'parses attributes as a Hash' do
        p = HashToTextParser.new({hash: {one: 1, two: 2}})
        expect(p.to_text).to eql "- hash.one = 1\n- hash.two = 2"
      end

      it 'parses attributes as a nested Hash' do
        p = HashToTextParser.new({hash: {one: 1, two: { three: 4 }}})
        expect(p.to_text).to eql "- hash.one = 1\n- hash.two.three = 4"
      end

      it 'parses attributes as a nested Hash with an array attribute' do
        p = HashToTextParser.new({hash: {one: { two: [3, 4, 'a'] }}})
        expect(p.to_text).to eql "- hash.one.two = [3, 4, a]"
      end

      it 'does not parse attributes as a nested Hash in an array' do
        p = HashToTextParser.new({ array: [ { one: 2 } ] })
        expect { p.to_text }.to raise_error(IllegalNestedHashError)
      end

      it "parses attribute on multiple lines" do
        query = "SUM(\n  1,\n  2\n)"
        p = HashToTextParser.new(message: "This\nis\nOK")

        expect(p.to_text).to eql("- message =\n    This\n    is\n    OK")
      end

      it 'parses attributes as a Set' do
        p = HashToTextParser.new({ set: Set.new(["a","b"]) })
        expect(p.to_text).to eql "- set = [a, b]"
      end

      it "parses comments" do
        p = HashToTextParser.new({ comments: "hi\nthere!" })
        expect(p.to_text).to eql "# hi\n# there!"
      end

      it "parses query on one line" do
        query = "SUM(1,2)"
        p = HashToTextParser.new({ queries: { demand: query } })
        expect(p.to_text).to eql "~ demand = #{ query }"
      end

      it 'parses Virtus objects into a hash' do
        p = HashToTextParser.new(
          doc: SomeDocument.new(unit: '%', query: 'ABC'))

        expect(p.to_text).to include("- doc.unit = %")
        expect(p.to_text).to include("- doc.query = ABC")
      end

      it "parses query on two lines" do
        query = "SUM(\n  1,\n  2\n)"
        p = HashToTextParser.new({ queries: { demand: query } })

        expect(p.to_text).to eql(<<-EOF.strip_heredoc.chomp("\n"))
          ~ demand =
              SUM(
                1,
                2
              )
        EOF
      end

      it "puts empty lines between comments and attributes" do
        hash = { comments: "hi!", foo: 'bar' }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "# hi!\n\n- foo = bar"
      end

      it "puts empty lines between attributes and query" do
        hash = { foo: 'bar', queries: { demand: 'SUM(1,2)' } }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "- foo = bar\n\n~ demand = SUM(1,2)"
      end

      it "puts empty lines between comments and query" do
        hash = { comments: 'hi', queries: { demand: 'SUM(1,2)' } }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "# hi\n\n~ demand = SUM(1,2)"
      end

    end # describe to_text

  end # describe HashToTextParser

end # module Atlas
