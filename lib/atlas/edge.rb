module Atlas
  # Edges connect two Nodes so that energy may flow from one to another. Each
  # edge has a carrier, which determines the type of energy flowing (e.g. gas,
  # coal, electricity, etc).
  #
  # The filename format for edges is:
  #
  #   CONSUMER-SUPPLIER@CARRIER
  #
  # For example:
  #
  #   coal_power_plant-coal_mine@coal
  #   electricity_grid-coal_power_plant@electricity
  class Edge
    include ActiveDocument

    DIRECTORY = 'edges'

    attribute :type,         Symbol
    attribute :demand,       Float
    attribute :parent_share, Float
    attribute :child_share,  Float
    attribute :reversed,     Boolean, default: false
    attribute :priority,     Integer

    attr_reader :supplier
    attr_reader :consumer
    attr_reader :carrier

    validates :supplier, presence: true
    validates :consumer, presence: true
    validates :carrier,  presence: true

    validates :type, inclusion:
      { in: [:share, :flexible, :constant, :inverse_flexible, :dependent] }

    validates_with QueryValidator, allow_no_query: true,
      attributes: [:child_share, :parent_share, :demand]

    # Public: The unique key which identifies this edge.
    #
    # This is a combination of the consumer (left node) and the supplier
    # (right node).
    #
    # Returns a Symbol.
    def key
      self.class.key(consumer, supplier, carrier)
    end

    # Public: Sets the key of the consumer ("child" or "left") node.
    #
    # consumer - The consumer node key as a string or symbol.
    #
    # Returns the key.
    def consumer=(consumer)
      @consumer = consumer && consumer.to_sym
    end

    # Public: Sets the key of the supplier ("parent" or "right") node.
    #
    # supplier - The supplier node key as a string or symbol.
    #
    # Returns the key.
    def supplier=(supplier)
      @supplier = supplier && supplier.to_sym
    end

    # Public: Sets the name of the carrier; the type of energy which passes
    # through the edge.
    #
    # carrier - The name of the carrier.
    #
    # Returns the key.
    def carrier=(carrier)
      @carrier = carrier && carrier.to_sym
    end

    # Public: Given +consumer+ and +supplier+ keys, and a +carrier+, returns
    # the key which would be assigned to an edge with those attributes.
    #
    # consumer - The key of the consumer node.
    # supplier - The key of the supplier node.
    # carrier  - The carrier key.
    #
    # Returns a Symbol.
    def self.key(consumer, supplier, carrier)
      :"#{ consumer }-#{ supplier }@#{ carrier }"
    end

    # Internal: The default value of the +sets+ attribute when no explicit
    # value is specified by the user.
    #
    # Returns a symbol or nil.
    def default_sets
      query && query.match(/\S/) ? :child_share : nil
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
      if name.nil? || ! name.match(/^[\w_]+-[\w_]+@[\w_]+$/)
        raise InvalidKeyError.new(name)
      end

      values = name.split(/[-@]/).map(&:to_sym)

      Hash[[:consumer, :supplier, :carrier].zip(values)]
    end

  end # Edge
end # Atlas
