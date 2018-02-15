module Atlas
    # Public: Builds the graph and exports it to a YAML file.
    #
    # dataset         - This dataset's graph will be built and persisted
    # path            - File to which the graph will be exported
    # export_modifier - Will be called on the graph's exported hash prior to saving it
    #
    # Returns a Hash
  GraphPersistor = lambda do |dataset, path, export_modifier: nil|
    graph = Runner.new(dataset).refinery_graph(:export)

    export_modifier.call(graph) if export_modifier

    data = EssentialExporter.dump(graph)
    File.write(path, data.to_yaml)
    data
  end
end
