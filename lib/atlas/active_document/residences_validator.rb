module Atlas
  module ActiveDocument
    class ResidencesValidator < ActiveModel::Validator
      def validate(record)
        return if record.present_number_of_apartments_before_1945.nil? ||
                  record.present_number_of_apartments_1945_1964.nil? ||
                  record.present_number_of_apartments_1965_1984.nil? ||
                  record.present_number_of_apartments_1985_2004.nil? ||
                  record.present_number_of_apartments_2005_present.nil? ||
                  record.present_number_of_detached_houses_before_1945.nil? ||
                  record.present_number_of_detached_houses_1945_1964.nil? ||
                  record.present_number_of_detached_houses_1965_1984.nil? ||
                  record.present_number_of_detached_houses_1985_2004.nil? ||
                  record.present_number_of_detached_houses_2005_present.nil? ||
                  record.present_number_of_semi_detached_houses_before_1945.nil? ||
                  record.present_number_of_semi_detached_houses_1945_1964.nil? ||
                  record.present_number_of_semi_detached_houses_1965_1984.nil? ||
                  record.present_number_of_semi_detached_houses_1985_2004.nil? ||
                  record.present_number_of_semi_detached_houses_2005_present.nil? ||
                  record.present_number_of_terraced_houses_before_1945.nil? ||
                  record.present_number_of_terraced_houses_1945_1964.nil? ||
                  record.present_number_of_terraced_houses_1965_1984.nil? ||
                  record.present_number_of_terraced_houses_1985_2004.nil? ||
                  record.present_number_of_terraced_houses_2005_present.nil?

        sum_of_residences = record.present_number_of_apartments_before_1945 +
                            record.present_number_of_apartments_1945_1964 +
                            record.present_number_of_apartments_1965_1984 +
                            record.present_number_of_apartments_1985_2004 +
                            record.present_number_of_apartments_2005_present +
                            record.present_number_of_detached_houses_before_1945 +
                            record.present_number_of_detached_houses_1945_1964 +
                            record.present_number_of_detached_houses_1965_1984 +
                            record.present_number_of_detached_houses_1985_2004 +
                            record.present_number_of_detached_houses_2005_present +
                            record.present_number_of_semi_detached_houses_before_1945 +
                            record.present_number_of_semi_detached_houses_1945_1964 +
                            record.present_number_of_semi_detached_houses_1965_1984 +
                            record.present_number_of_semi_detached_houses_1985_2004 +
                            record.present_number_of_semi_detached_houses_2005_present +
                            record.present_number_of_terraced_houses_before_1945 +
                            record.present_number_of_terraced_houses_1945_1964 +
                            record.present_number_of_terraced_houses_1965_1984 +
                            record.present_number_of_terraced_houses_1985_2004 +
                            record.present_number_of_terraced_houses_2005_present

        unless record.present_number_of_residences.round == sum_of_residences.round
          record.errors.add(:present_number_of_residences,
            "Number of residences per type and construction year "\
            "don't add up to the total number of residences "\
            "(#{ record.present_number_of_residences })."
          )
        end
      end
    end
  end
end
