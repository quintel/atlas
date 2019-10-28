# frozen_string_literal: true

module Atlas
  module ActiveDocument
    class ResidencesValidator < ActiveModel::Validator
      def validate(record)
        return if record.number_of_apartments.nil? ||
          record.number_of_terraced_houses.nil? ||
          record.number_of_corner_houses.nil? ||
          record.number_of_detached_houses.nil? ||
          record.number_of_semi_detached_houses.nil?

        sum_of_residences = record.number_of_apartments +
          record.number_of_terraced_houses +
          record.number_of_corner_houses +
          record.number_of_detached_houses +
          record.number_of_semi_detached_houses

        unless record.number_of_residences.round == sum_of_residences.round
          record.errors.add(:number_of_residences,
            "Number of apartments (#{record.number_of_apartments}) "\
            "Number of terraced houses (#{record.number_of_terraced_houses}) "\
            "Number of corner houses (#{record.number_of_corner_houses}) "\
            "Number of detached houses (#{record.number_of_detached_houses}) "\
            "Number of semi detached houses (#{record.number_of_semi_detached_houses}) "\
            "don't add up to the total number of residences "\
            "(#{record.number_of_residences}).")
        end
      end
    end
  end
end
