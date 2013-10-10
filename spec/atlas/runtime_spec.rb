require 'spec_helper'

module Atlas

  describe Runtime do
    let(:dataset) { Dataset.find(:nl) }
    let(:graph)   { Turbine::Graph.new }
    let(:runtime) { Runtime.new(dataset, graph) }

    let!(:parent)       { graph.add(Turbine::Node.new(:parent)) }
    let!(:child)        { graph.add(Turbine::Node.new(:child)) }
    let!(:orphan)       { graph.add(Turbine::Node.new(:orphan)) }

    let!(:pc_elec_edge) { parent.connect_to(child, :electricity) }
    let!(:pc_gas_edge)  { parent.connect_to(child, :gas) }
    let!(:cp_gas_edge)  { child.connect_to(parent, :gas) }

    it "executes basic ruby code" do
      expect(runtime.execute("1+1")).to eql 2
      expect(runtime.execute("[1,2,3].reduce(:+)")).to eql 6
    end

    it "executes standard function from Rubel" do
      expect(runtime.execute("SUM(1,2)")).to eql 3
    end

    context 'EB' do
      it "executes Energy Balance functions" do
        expect(runtime.execute("EB('Residential', 'Natural Gas')")).to be > -1
      end

      it "executes Energy Balance functions without quotes" do
        expect(runtime.execute("EB(residential, natural_gas)")).to be > -1
      end
    end

    context 'AREA' do
      it "executes Area functions" do
        expect(runtime.execute("AREA(number_inhabitants)")).to be > -1
      end
    end

    context 'SHARE' do
      it 'executes SHARE functions' do
        expect(runtime.execute("SHARE(cars, gasoline)")).to eq(0.1)
      end

      it 'raises an error if the SHARE data is missing' do
        expect { runtime.execute('SHARE(cars, nope)') }.
          to raise_error(UnknownCSVRowError)
      end
    end

    context 'EFFICIENCY' do
      it 'executes EFFICIENCY functions' do
        result = runtime.execute("EFFICIENCY(transformation, output, coal)")
        expect(result).to eq(0.1)
      end

      it 'raises an error if the EFFICIENCY data is missing' do
        expect { runtime.execute('EFFICIENCY(transformation, a, b)') }.
          to raise_error(UnknownCSVRowError)
      end
    end

    context 'TIME_CURVE' do
      it 'executes TIME_CURVE functions' do
        result = runtime.execute("TIME_CURVE(bio_residues, max_demand)")
        expect(result).to eq(34)
      end

      it 'raises an error if the curve data is missing' do
        expect { runtime.execute('TIME_CURVE(nope, nope)') }.
          to raise_error(/no such file or directory/i)
      end
    end

    context 'CENTRAL_PRODUCTION' do
      it 'executes CENTRAL_PRODUCTION functions' do
        expect(runtime.execute(
          "CENTRAL_PRODUCTION(energy_production_algae_diesel)"
        )).to eq(125)
      end

      it 'raises an error if the production data is missing' do
        expect { runtime.execute('CENTRAL_PRODUCTION(nope)') }.
          to raise_error(UnknownCSVRowError)
      end
    end

    context 'PRIMARY_PRODUCTION' do
      it 'executes PRIMARY_PRODUCTION functions' do
        expect(runtime.execute(
          "PRIMARY_PRODUCTION(energy_production_non_biogenic_waste, demand)"
        )).to eq(31202)
      end

      it "raises an error if you don't provide a column name" do
        expect {
          runtime.execute(
            "PRIMARY_PRODUCTION(energy_production_non_biogenic_waste)")
        }.to raise_error(ArgumentError)
      end

      it 'raises an error if the production data is missing' do
        expect { runtime.execute('PRIMARY_PRODUCTION(nope, demand)') }.
          to raise_error(UnknownCSVRowError)
      end
    end

    context 'DEMAND' do
      it 'executes DEMAND functions' do
        expect(
          runtime.execute("DEMAND(industry, final_demand_coal_gas)")
        ).to eq(132)
      end

      it "raises an error if you don't provide a node key" do
        expect {
          runtime.execute("DEMAND(industry)")
        }.to raise_error(ArgumentError)
      end

      it "raises an error if you don't provide an invalid node key" do
        expect {
          runtime.execute("DEMAND(industry, not_there)")
        }.to raise_error(UnknownCSVRowError)
      end

      it 'raises an error if the named file is missing' do
        expect { runtime.execute('DEMAND(nope, demand)') }.
          to raise_error(Errno::ENOENT)
      end
    end
  end # Runtime
end # Atlas
