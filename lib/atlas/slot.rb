module Atlas
  # Slots aggregate multiple edges of the same carrier on a node. Nodes have
  # input slots - slots through which energy flows into the node - and output
  # slots - slots through which energy leaves.
  class Slot
    include Virtus.model
    include ActiveModel::Validations

    KEY_FORMAT = /^(?<node>[\w_]+)(?<direction>[+-])@(?<carrier>[\w_]+)$/

    attribute :node,      Atlas::Node
    attribute :direction, Symbol
    attribute :carrier,   Symbol

    validates :share, numericality: true, allow_nil: true

    # Public: A human-readable version of the Slot for debugging.
    #
    # Returns a string.
    def inspect
      "#<#{ self.class.name } node=#{ node.key } " \
        "carrier=#{ carrier } direction=#{ direction }>"
    end

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

      # No special behaviour for input slots.
      return Slot.new(attributes) if direction == :in

      share = node.output[carrier]

      if Slot::Elastic.elastic?(share)
        Slot::Elastic.new(attributes)
      elsif Slot::Dynamic.dynamic?(share)
        Slot::Dynamic.new(attributes)
      elsif share.is_a?(Hash)
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
      ! in?
    end

    # Public: The proportion of energy which enters or leaves the node through
    # this slot.
    #
    # Returns a numeric.
    def share
      in? ? node.input[carrier] : node.output[carrier]
    end

    # Public: The Rubel query which will calculate the share of the slot, if
    # one is present.
    #
    # Returns a string.
    def query
      node.queries[:"#{ in? ? :input : :output }.#{ carrier }"]
    end

    # Internal: Given the key of a Slot, creates a hash of the attributes
    # extracted from the filename.
    #
    # Returns a hash.
    def self.attributes_from_key(key)
      if key.nil? || ! (data = key.to_s.match(KEY_FORMAT))
        fail InvalidKeyError.new(key)
      end

      { node:      data[:node].to_sym,
        direction: data[:direction] == '+' ? :in : :out,
        carrier:   data[:carrier].to_sym }
    end
  end
end
