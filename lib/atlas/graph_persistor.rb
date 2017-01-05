module Atlas
  class GraphPersistor
    def initialize(dataset, path)
      @dataset = dataset
      @path    = path
    end

    def self.call(dataset, path)
      new(dataset, path).persist!
    end

    def persist!
      File.open(@path, 'w') do |f|
        f.write EssentialExporter.dump(refinery_graph).to_yaml
      end
    end

    private

    def refinery_graph
      Runner.new(@dataset).refinery_graph(:export)
    end
  end
end
