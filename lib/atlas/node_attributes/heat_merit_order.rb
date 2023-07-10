# frozen_string_literal: true

require_relative './merit_order'

module Atlas
  module NodeAttributes
    # Contains information about the node's participation in the heat
    # merit order calculation.
    class HeatMeritOrder < MeritOrder
      values do
        # Defines whether the node is on the HT, MT or LT network.
        attribute :temperature, Symbol, default: :ht
      end

      validates :temperature, inclusion: %i[lt mt ht]
    end
  end
end
