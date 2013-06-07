module Tome
  # Slots aggregate multiple edges of the same carrier on a node. Nodes have
  # input slots - slots through which energy flows into the node - and output
  # slots - slots through which energy leaves.
  #
  # The filename format for slots is:
  #
  #   NODE_KEY[+-]@CARRIER
  #
  # The plus (+) and (-) indicate whether the slot is input or output. Plus
  # is like *adding* energy to a node, so this represents an input slot. Minus
  # subtracts energy from the node, so it is an output slot.
  #
  # For example:
  #
  #   foo-@gas          # An gas output slot on the "foo" node.
  #   bar+@electricity  # An electricity input slot on the "bar" node.
  class Slot
    include ActiveDocument

    FILENAME  = /^(?<node>[\w_]+)(?<direction>[+-])@(?<carrier>[\w_]+)$/
    DIRECTORY = 'slots'

    # What proportion of the total energy flow in or out of the node is
    # through this slot?
    attribute :share, Float, default: 1.0

    # Public: The key of the node to which the slot beings.
    #
    # Returns a Symbol.
    attr_accessor :node

    # Public: Is this a slot through which energy flow +:in+ to the node, or
    # flows +:out+?
    #
    # Returns a Symbol.
    attr_accessor :direction

    # Public: The carrier key.
    #
    # Returns a Symbol.
    attr_accessor :carrier

    attribute :query, String
    attribute :type,  Symbol

    validates :node,      presence: true
    validates :direction, presence: true, inclusion: { in: [:in, :out] }
    validates :carrier,   presence: true

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
      self.class.key(node, direction, carrier)
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

    #######
    private
    #######

    # Internal: Given the name of the ActiveDocument file, without a
    # subclass suffix or file extension, creates a hash of the attributes
    # extracted from the filename.
    #
    # Returns a hash.
    def attributes_from_basename(name)
      if name.nil? || ! (data = name.match(FILENAME))
        raise InvalidKeyError.new(name)
      end

      { node:      data[:node].to_sym,
        direction: data[:direction] == '+' ? :in : :out,
        carrier:   data[:carrier].to_sym }
    end
  end # Slot
end # Tome
