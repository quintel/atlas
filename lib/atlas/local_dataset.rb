module Atlas
  class LocalDataset
    DIRECTORY = 'local_datasets'

    include ActiveDocument

    attribute :name, String
    attribute :scaling, Hash
  end
end
