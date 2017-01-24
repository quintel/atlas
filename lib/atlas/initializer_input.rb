module Atlas
  class InitializerInput
    include ActiveDocument

    DIRECTORY = 'initializer_inputs'

    attribute :query,           String
    attribute :share_group,     Symbol
    attribute :priority,        Integer, default: 0
    attribute :unit,            String
    attribute :update_type,     String

    validates_presence_of :query
  end
end
