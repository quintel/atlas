module Atlas
  class Runner
    # Iterates through each node in the graph, converting the "efficiency"
    # attribute, if present, to the appropriate slot shares.
    module SetSlotSharesFromEfficiency
      def self.with_queryable(query)
        lambda do |refinery|
          refinery.nodes.each do |node|
            model = node.get(:model)

            (model.out_slots + model.in_slots).each do |slot|
              collection = node.slots.public_send(slot.direction)

              # Temporary storage of coupling carrier shares which are
              # calculated using a query,
              if slot.carrier == :coupling_carrier
                if slot.query
                  node.set(:"cc_#{ slot.direction }", query.call(slot.query))
                elsif slot.share
                  node.set(:"cc_#{ slot.direction }", slot.share)
                end

                next
              end

              if collection.include?(slot.carrier)
                ref_slot = collection.get(slot.carrier)
              else
                ref_slot = collection.add(slot.carrier)
              end

              ref_slot.set(:model, slot)
              ref_slot.set(:type, :elastic) if slot.is_a?(Slot::Elastic)


              if slot.query
                ref_slot.set(:share, query.call(slot.query))
              elsif slot.share
                ref_slot.set(:share, slot.share)
              elsif slot.is_a?(Slot::CarrierEfficient)
                ref_slot.set(:share, carrier_efficient_share(query, slot, model))
              end
            end
          end

          refinery
        end
      end

      def self.carrier_efficient_share(query, slot, node)
        input_queries = Hash[
          slot.dependencies.map do |carrier|
            [carrier, node.queries["input.#{carrier}".to_sym]]
          end.compact
        ]

        slot.calculate_share(input_queries.transform_values { |value| query.call(value) })
      end
    end
  end
end
