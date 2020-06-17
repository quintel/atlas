module Atlas
  class Gquery
    include ActiveDocument

    extension_name 'gql'

    attribute :query,          String
    attribute :unit,           String
    attribute :deprecated_key, String

  end
end
