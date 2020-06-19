# frozen_string_literal: true

require_relative 'demand'

module Atlas
  class EnergyNode
    # A central producer node automatically takes its demand and full load hours from a CSV.
    class CentralProducer < Demand
      # Public: The query used to extract a demand from the central producers
      # CSV data.
      #
      # Returns a string.
      def queries
        {
          demand: "CENTRAL_PRODUCTION(#{key}, demand)",
          full_load_hours: "CENTRAL_PRODUCTION(#{key}, full_load_hours)"
        }.merge(super)
      end
    end
  end
end
