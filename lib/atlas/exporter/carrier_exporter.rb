# frozen_string_literal: true

module Atlas
  module Exporter
    # Exports the data carriers, calculating any dataset-specific queries as-needed.
    module CarrierExporter
      module_function

      # Public: Creates a Hash representing data for carriers.
      #
      # carriers - An array of carriers for which data will be exported.
      # runtime  - An Atlas::Runtime instance, so that queries may be calculated.
      #
      # Returns a hash where each key matches the carrier key, and each value is the data for the
      # carrier.
      def dump_collection(carriers, runtime)
        carriers.each_with_object({}) do |carrier, data|
          data[carrier.key] = dump(carrier, runtime)
        end
      end

      # Public: Creates a Hash representing data for a single carrier.
      #
      # carriers - A carriers for which data will be exported.
      # runtime  - An Atlas::Runtime instance, so that queries may be calculated.
      #
      # Returns a hash.
      def dump(carrier, runtime)
        data = carrier.to_h

        carrier.queries.each do |key, query|
          data[key] = runtime.execute_checked(query)
        end

        data
      end
    end
  end
end
