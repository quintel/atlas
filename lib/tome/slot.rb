module Tome
  # Slots aggregate multiple edges of the same carrier on a node. Nodes have
  # input slots - slots through which energy flows into the node - and output
  # slots - slots through which energy leaves.
  class Slot
    include Virtus

    KEY_FORMAT = /^(?<node>[\w_]+)(?<direction>[+-])@(?<carrier>[\w_]+)$/

    attribute :node,      Tome::Node
    attribute :direction, Symbol
    attribute :carrier,   Symbol

    # Public: Given the +node+ key, +direction+, and +carrier+, returns the
    # key which would be assigned to a Slot with those attributes.
    #
    # node      - The node key.
    # direction - The direction of the slot; :in or :out.
    # carrier   - The name of the carrier.
    #
    # Returns a Symbol.
    def self.key(node, direction, carrier)
      :"#{ node }#{ direction == :in ? '+' : '-' }@#{ carrier }"
    end

    # Public: Given a node, direction, and carrier, returns a Slot instance.
    #
    # This determines if a "special" slot is needed, such as a loss slot, or
    # carrier-efficiency slot.
    #
    # Returns a Slot.
    def self.slot_for(node, direction, carrier)
      direction  = direction.to_sym
      carrier    = carrier.to_sym

      attributes = { node: node, direction: direction, carrier: carrier }

      if direction == :in
        # No special behaviour for input slots.
        Slot.new(attributes)
      elsif node.output[carrier] == :elastic
        # Elastic slots automatically fill whatever share isn't filled by the
        # other output slots. Commonly used for loss.
        Slot::Elastic.new(attributes)
      elsif node.output[carrier].is_a?(Hash)
        # Carrier efficient slot; share depends on the proportion of inputs.
        Slot::CarrierEfficient.new(attributes)
      else
        Slot.new(attributes)
      end
    end

    # Public: The unique key used to identify the document.
    #
    # Returns a Symbol.
    def key
      self.class.key(node.key, direction, carrier)
    end

    # Public: Is the direction of this Slot +:in+?
    #
    # Returns true or false.
    def in?
      direction == :in
    end

    # Public: Is the direction of this Slot +:out+?
    #
    # Returns true or false.
    def out?
      not in?
    end

    # Public: The proportion of energy which enters or leaves the node through
    # this slot.
    #
    # Returns a numeric.
    def share
      share = (in? ? node.input[carrier] : node.output[carrier])
      share == :elastic ? nil : share
    end

    # Internal: Given the key of a Slot, creates a hash of the attributes
    # extracted from the filename.
    #
    # Returns a hash.
    def self.attributes_from_key(key)
      if key.nil? || ! (data = key.to_s.match(KEY_FORMAT))
        raise InvalidKeyError.new(key)
      end

      { node:      data[:node].to_sym,
        direction: data[:direction] == '+' ? :in : :out,
        carrier:   data[:carrier].to_sym }
    end
  end # Slot
end # Tome
