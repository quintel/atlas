module Atlas
  class GraphPersistor
    def initialize(dataset, derived_dataset)
      @dataset         = dataset
      @derived_dataset = derived_dataset
    end

    def self.call(dataset, derived_dataset)
      new(dataset, derived_dataset).persist!
    end

    def persist!
      File.open(@derived_dataset.graph_path, 'w') do |f|
        f.write EssentialExporter.dump(
          refinery_graph, @derived_dataset.scaling_factor).to_yaml
      end
    end

    private

    def refinery_graph
      Runner.new(@dataset, GraphBuilder.build).refinery_graph(:export)
    end
  end
end
