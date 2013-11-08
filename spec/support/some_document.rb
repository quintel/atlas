module Atlas
  class SomeDocument
    include ActiveDocument

    attribute :comments, String
    attribute :unit,     String
    attribute :hash,     Hash[Symbol => String]
    attribute :array,    Array[Symbol]
    attribute :query,    String

    # Ignore validation except in the validation tests.
    validates :query, presence: true, if: :do_validation
    attr_accessor :do_validation

    FILE_SUFFIX = 'suffix'
    DIRECTORY   = 'active_document'
  end

  class SomeDocument::OtherDocument < SomeDocument
  end

  class SomeDocument::FinalDocument < SomeDocument::OtherDocument
    attribute :sets, String
  end
end # Atlas
