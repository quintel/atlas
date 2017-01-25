module Atlas
  module InputHelper
    extend ActiveSupport::Concern

    module ClassMethods
      # Public: Creates a hash where each key is the name of a share group, and
      # each value an array containing the inputs belonging to the group.
      #
      # Inputs which do not belong to a share group are not included.
      #
      # Returns a hash.
      def by_share_group
        all.select(&:share_group).each_with_object({}) do |input, groups|
          groups[input.share_group] ||= []
          groups[input.share_group].push(input)
        end
      end
    end
  end
end
