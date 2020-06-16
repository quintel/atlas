module Atlas
  class Gquery
    include ActiveDocument

    FILE_SUFFIX = 'gql'

    attribute :query,          String
    attribute :unit,           String
    attribute :deprecated_key, String

  end
end
