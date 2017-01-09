module Atlas
  class GraphPersistor
    def initialize(dataset, path, export_modifier: nil)
      @dataset        = dataset
      @path           = path
      @export_modifier = export_modifier
    end

    def self.call(dataset, path, export_modifier: nil)
      new(dataset, path, export_modifier: export_modifier).persist!
    end

    def persist!
      data = EssentialExporter.dump(refinery_graph)
      @export_modifier.call(data) if @export_modifier
      File.open(@path, 'w') do |f|
        f.write data.to_yaml
      end
    end

    private

    def refinery_graph
      Runner.new(@dataset).refinery_graph(:export)
    end
  end
end
