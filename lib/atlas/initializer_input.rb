# frozen_string_literal: true

module Atlas
  # This is deprecated!
  class InitializerInput
    include ActiveDocument
    include InputHelper

    DIRECTORY = 'initializer_inputs'

    attribute :query,           String
    attribute :share_group,     Symbol
    attribute :priority,        Integer, default: 0
    attribute :update_type,     String

    validates_presence_of :query
    validates :update_type, inclusion: { in: [nil, '%', 'factor'] }
  end
end
