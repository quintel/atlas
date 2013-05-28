module ETSource
  class SomeDocument
    include ActiveDocument

    attribute :description, String
    attribute :unit,        String
    attribute :query,       String

    # Ignore validation except in the validation tests.
    validates :query, presence: true, if: :do_validation
    attr_accessor :do_validation

    FILE_SUFFIX = 'suffix'
    DIRECTORY   = 'active_document'
  end

  class OtherDocument < SomeDocument
  end

  class FinalDocument < OtherDocument
  end
end # ETSource
