module Atlas
  class Scaler::GraphPersistor
    def initialize(dataset, path)
      @dataset = dataset
      @graph   = GraphBuilder.build
      @path    = path
    end

    def persist_graph
      File.open(file_path, 'w') do |f|
        f.write Scaler::GraphExporter.new(refinery_graph).export
      end
    end

    private

    def refinery_graph
      Runner.new(@dataset, @graph).refinery_graph
    end

    def file_path
      File.join(Atlas.data_dir, Dataset::DerivedDataset::DIRECTORY, @path,
        Dataset::DerivedDataset::GRAPH)
    end
  end
end
