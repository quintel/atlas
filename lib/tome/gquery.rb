module Tome
  class Gquery
    include ActiveDocument

    FILE_SUFFIX = 'gql'
    DIRECTORY   = 'gqueries'

    attribute :description,    String
    attribute :query,          String
    attribute :unit,           String
    attribute :deprecated_key, String

  end # Guery
end #  Tome