module Atlas
  # Edges connect two Nodes so that energy may flow from one to another. Each
  # edge has a carrier, which determines the type of energy flowing (e.g. gas,
  # coal, electricity, etc).
  #
  # The filename format for edges is:
  #
  #   SUPPLIER_CONSUMER@CARRIER
  #
  # For example:
  #
  #   coal_mine-coal_power_plant@coal
  #   infinite_improbability_drive-electricity_grid@electricity
  class Edge
    include ActiveDocument

    directory_name 'graphs/energy/edges'

    attribute :type,          Symbol
    attribute :demand,        Float
    attribute :parent_share,  Float
    attribute :child_share,   Float
    attribute :reversed,      Boolean, default: false
    attribute :priority,      Integer
    attribute :groups,        Array[Symbol]
    attribute :graph_methods, Array[String]

    attr_reader :supplier
    attr_reader :consumer
    attr_reader :carrier

    validates :supplier, presence: true
    validates :consumer, presence: true
    validates :carrier,  presence: true

    validates :type, inclusion:
      { in: [:share, :flexible, :constant, :inversed_flexible, :dependent] }

    validates_with QueryValidator, allow_no_query: true,
      attributes: [:child_share, :parent_share, :demand]

    validate :validate_associated_documents

    # Public: The unique key which identifies this edge.
    #
    # This is a combination of the consumer (left node) and the supplier
    # (right node).
    #
    # Returns a Symbol.
    def key
      self.class.key(supplier, consumer, carrier)
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
    # supplier - The key of the supplier node.
    # consumer - The key of the consumer node.
    # carrier  - The carrier key.
    #
    # Returns a Symbol.
    def self.key(supplier, consumer, carrier)
      :"#{ supplier }-#{ consumer }@#{ carrier }"
    end

    private

    # Internal: Given the name of the ActiveDocument file, without a
    # subclass suffix or file extension, creates a hash of the attributes
    # extracted from the filename.
    #
    # Returns a hash.
    def attributes_from_basename(name)
      if name.nil? || ! name.match(/^[\w_]+-[\w_]+@[\w_]+$/)
        fail InvalidKeyError.new(name)
      end

      values = name.split(/[-@]/).map(&:to_sym)

      Hash[[:supplier, :consumer, :carrier].zip(values)]
    end

    def validate_associated_documents
      if carrier && ! Carrier.manager.key?(carrier)
        errors.add(:carrier, 'does not exist')
      end

      if supplier && ! Node.manager.key?(supplier)
        errors.add(:supplier, 'does not exist')
      end

      if consumer && ! Node.manager.key?(consumer)
        errors.add(:consumer, 'does not exist')
      end
    end

  end
end
