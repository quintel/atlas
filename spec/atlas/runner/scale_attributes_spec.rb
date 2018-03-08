require 'spec_helper'

module Atlas
  describe Runner::ScaleAttributes do
    let(:dataset)  { Dataset.find(:groningen) }
    let(:catalyst) { Runner::ScaleAttributes.with_dataset(dataset) }

    context "with a graph" do
      let(:graph) {
        graph = Turbine::Graph.new

        a = graph.add(
          Refinery::Node.new(:a,
            demand: 1000,
            model: Atlas::Node.find(:bar)
          )
        )

        b = graph.add(
          Refinery::Node.new(:b,
            demand: 2000,
            model: Atlas::Node.find(:baz)
          )
        )

        e = a.connect_to(b, :gas)
        e.set(:demand, 500)
        graph
      }

      let(:scaled_graph) { catalyst.call(graph) }

      it "demand of node a should be 1.0" do
        expect(scaled_graph.node(:a).demand).to eq(1.0)
      end

      it "demand of node b should be 2000" do
        expect(scaled_graph.node(:b).demand).to eq(2000.0)
      end

      it "demand of edge a-b@gas should be 0.5" do
        expect(scaled_graph.node(:a).edges(:out).first.get(:demand)).to eq(0.5)
      end
    end
  end
end
