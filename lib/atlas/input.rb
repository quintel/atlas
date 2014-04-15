module Atlas
  class Input
    include ActiveDocument

    DIRECTORY = 'inputs'

    attribute :query,           String
    attribute :share_group,     Symbol
    attribute :label,           String
    attribute :label_query,     String
    attribute :comments,        String
    attribute :priority,        Integer, default: 0

    attribute :max_value,       Float
    attribute :max_value_gql,   String
    attribute :min_value,       Float
    attribute :min_value_gql,   String
    attribute :start_value,     Float
    attribute :start_value_gql, String
    attribute :step_value,      Float
    attribute :factor,          Float

    attribute :unit,            String
    attribute :update_period,   String
    attribute :update_type,     String
    attribute :default_unit,    String
    attribute :dependent_on,    String

    validates_presence_of :query

    # Public: Creates a hash where each key is the name of a share group, and
    # each value an array containing the inputs belonging to the group.
    #
    # Inputs which do not belong to a share group are not included.
    #
    # Returns a hash.
    def self.by_share_group
      grouped_inputs = Input.all.select(&:share_group)

      grouped_inputs.each_with_object({}) do |input, groups|
        groups[input.share_group] ||= []
        groups[input.share_group].push(input)
      end
    end
  end # Input
end # Atlas
