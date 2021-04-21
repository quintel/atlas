# frozen_string_literal: true

module Atlas
  # Exports graph-based data for a region.
  module Exporter
    # Public: Given a Runner, returns the Hash with all the exported values for nodes, edges, and
    # carriers.
    #
    # Returns a Hash.
    def self.dump(runner)
      data = GraphExporter.dump(runner.refinery_graph)
      data[Carrier.name] = CarrierExporter.dump_collection(Carrier.all, runner.runtime)
      data
    end
  end
end
