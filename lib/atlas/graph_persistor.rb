module Atlas
  class GraphPersistor
    def initialize(dataset, path)
      @dataset = dataset
      @path    = path
    end

    def persist_graph
      File.open(file_path, 'w') do |f|
        f.write GraphExporter.new(refinery_graph).to_h
      end
    end

    private

    def refinery_graph
      Runner.new(@dataset, GraphBuilder.build).refinery_graph
    end

    def file_path
      File.join(Atlas.data_dir, Dataset::DerivedDataset::DIRECTORY, @path,
        Dataset::DerivedDataset::GRAPH)
    end
  end
end
