require 'spec_helper'

module Atlas
  describe Runner::SetAttributesFromGraphValues do
    let(:dataset) { Dataset.find(:groningen) }
    let(:catalyst) {
      Runner::SetAttributesFromGraphValues.with_dataset(dataset)

    }

    context "with a graph" do
      let(:graph) { GraphBuilder.build }
      let(:valued_graph) { catalyst.call(graph) }

      it "sets the demand of bar" do
        expect(valued_graph
          .node(:bar)
          .get(:demand)
        ).to eq(5.0)
      end

      it "sets the number of units of bar" do
        expect(valued_graph
          .node(:bar)
          .get(:number_of_units)
        ).to eq(1.0)
      end

      it "sets the output slot share of node bar" do
        expect(valued_graph
          .node(:bar)
          .slots
          .out
          .get(:coal)
          .get(:share)
        ).to eq(0.4)
      end

      it "sets the input slot share of node fd" do
        expect(valued_graph
          .node(:fd)
          .slots
          .in
          .get(:corn)
          .get(:share)
        ).to eq(0.4)
      end
      it "sets the share of an edge" do
        expect(valued_graph
          .node(:bar)
          .edges(:out)
          .first
          .get(:share)
        ).to eq(0.5)
      end
    end
  end
end
