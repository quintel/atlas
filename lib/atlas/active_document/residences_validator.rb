module Atlas
  module ActiveDocument
    class ResidencesValidator < ActiveModel::Validator
      def validate(record)
        return if record.number_of_old_residences.nil? ||
                  record.number_of_new_residences.nil?

        sum_of_residences = record.number_of_old_residences +
                            record.number_of_new_residences

        unless record.number_of_residences.round == sum_of_residences.round
          record.errors.add(:number_of_residences,
            "Number of old residences (#{ record.number_of_old_residences}) "\
            "and number of new residences (#{ record.number_of_new_residences }) "\
            "don't add up to the total number of residences "\
            "(#{ record.number_of_residences })."
          )
        end
      end
    end
  end
end
