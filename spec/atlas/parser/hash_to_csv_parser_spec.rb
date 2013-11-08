require 'spec_helper'

module Atlas
  describe HashToCSVParser, :fixtures do

    let(:hash) do
      { unit: "%",
        bar:  "blah",
        hash: { one: "two" },
      }
    end

    describe '#to_csv' do

      it 'parses correctly' do
        expect(HashToCSVParser.new(hash).to_csv).to eql \
          "unit,%\n" +
          "bar,blah\n" +
          "hash.one,two"
      end

    end # to_csv
  end # HashToCSVParser
end # Atlas::Parser
