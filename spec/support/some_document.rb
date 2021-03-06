module Atlas
  class SomeDocument
    include ActiveDocument

    directory_name 'active_document'
    extension_name 'suffix'

    attribute :comments, String
    attribute :unit,     String
    attribute :query,    String

    # Ignore validation except in the validation tests.
    validates :query, presence: true, if: :do_validation
    attr_accessor :do_validation
  end

  class SomeDocument::OtherDocument < SomeDocument
  end

  class SomeDocument::FinalDocument < SomeDocument::OtherDocument
    attribute :sets, String
  end
end
