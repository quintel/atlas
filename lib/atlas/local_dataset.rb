module Atlas
  class LocalDataset
    DIRECTORY = 'local_datasets'.freeze
    GRAPH     = 'graph.yml'.freeze

    include ActiveDocument

    attribute :name, String
    attribute :scaling, Hash

    def graph
      YAML.load_file(File.join(directory, name, GRAPH))
    end
  end
end
