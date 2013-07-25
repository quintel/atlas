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

      it 'parses attributes as a Set' do
        p = HashToTextParser.new({set: Set.new(["a","b"])})
        expect(p.to_text).to eql "- set = [a, b]"
      end

      it "parses comments" do
        p = HashToTextParser.new({comments: "hi\nthere!"})
        expect(p.to_text).to eql "# hi\n# there!"
      end

      it "parses query on one line" do
        query = "SUM(1+2)"
        p = HashToTextParser.new({query: query})
        expect(p.to_text).to eql query
      end

      it "parses query on two lines" do
        query = "SUM\n  (1,\n  2\n)"
        p = HashToTextParser.new({query: query})
        expect(p.to_text).to eql query
      end

      it "puts empty lines between comments and attributes" do
        hash = { comments: "hi!", foo: 'bar' }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "# hi!\n\n- foo = bar"
      end

      it "puts empty lines between attributes and query" do
        hash = { foo: 'bar', query: "SUM(1,2)" }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "- foo = bar\n\nSUM(1,2)"
      end

      it "puts empty lines between comments and query" do
        hash = { comments: 'hi', query: "SUM(1,2)" }
        p = HashToTextParser.new(hash)
        expect(p.to_text).to eql "# hi\n\nSUM(1,2)"
      end

    end # describe to_text

  end # describe HashToTextParser

end # module Atlas
