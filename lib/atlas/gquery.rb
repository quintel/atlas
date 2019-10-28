# frozen_string_literal: true

module Atlas
  class Gquery
    include ActiveDocument

    FILE_SUFFIX = 'gql'
    DIRECTORY   = 'gqueries'

    attribute :query,          String
    attribute :unit,           String
    attribute :deprecated_key, String
  end
end
