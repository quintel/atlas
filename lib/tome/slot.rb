module Tome
  # Slots aggregate multiple edges of the same carrier on a node. Nodes have
  # input slots - slots through which energy flows into the node - and output
  # slots - slots through which energy leaves.
  class Slot
    include Virtus

    KEY_FORMAT = /^(?<node>[\w_]+)(?<direction>[+-])@(?<carrier>[\w_]+)$/

    attribute :share,     Float, default: 1.0
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

    # Public: Sets the share of the slot.
    #
    # Returns whatever you gave.
    def share=(value)
      super(value == :elastic ? nil : value)
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
