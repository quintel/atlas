# frozen_string_literal: true

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
  module Edge
    extend ActiveSupport::Concern

    included do
      include ActiveDocument

      attribute :type,          Symbol
      attribute :demand,        Float
      attribute :parent_share,  Float
      attribute :child_share,   Float
      attribute :reversed,      Virtus::Attribute::Boolean, default: false
      attribute :priority,      Integer
      attribute :groups,        Array[Symbol]
      attribute :graph_methods, Array[String]

      attr_reader :supplier
      attr_reader :consumer
      attr_reader :carrier

      validates :supplier, presence: true
      validates :consumer, presence: true
      validates :carrier,  presence: true

      validates :type, inclusion: { in: %i[constant dependent flexible inversed_flexible share] }

      validates_with ActiveDocument::QueryValidator,
        allow_no_query: true,
        attributes: %i[child_share demand parent_share]

      validate :validate_associated_documents

      include InstanceMethods
    end

    # Class methods used on classes which include Edge.
    module ClassMethods
      # Public: Returns the GraphConfig::Config object which has information about the graph to
      # which the edge belongs.
      def graph_config
        raise NotImplementedError
      end

      # Public: Given +consumer+ and +supplier+ keys, and a +carrier+, returns
      # the key which would be assigned to an edge with those attributes.
      #
      # supplier - The key of the supplier node.
      # consumer - The key of the consumer node.
      # carrier  - The carrier key.
      #
      # Returns a Symbol.
      def key(supplier, consumer, carrier)
        :"#{supplier}-#{consumer}@#{carrier}"
      end
    end

    # InstanceMethods have to be defined in a separate module, and included at the end of the
    # above `included` block, otherwise the Virtus attributes will override any custom
    # implementation.
    module InstanceMethods
      # Public: The unique key which identifies this edge.
      #
      # This is a combination of the consumer (left node) and the supplier (right node).
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
        @consumer = consumer&.to_sym
      end

      # Public: Sets the key of the supplier ("parent" or "right") node.
      #
      # supplier - The supplier node key as a string or symbol.
      #
      # Returns the key.
      def supplier=(supplier)
        @supplier = supplier&.to_sym
      end

      # Public: Sets the name of the carrier; the type of energy which passes through the edge.
      #
      # carrier - The name of the carrier.
      #
      # Returns the key.
      def carrier=(carrier)
        @carrier = carrier&.to_sym
      end

      # See Edge.graph_config
      def graph_config
        self.class.graph_config
      end

      private

      # Internal: Given the name of the ActiveDocument file, without a subclass suffix or file
      # extension, creates a hash of the attributes extracted from the filename.
      #
      # Returns a hash.
      def attributes_from_basename(name)
        raise(InvalidKeyError, name) if name.nil? || !name.match(/^[\w_]+-[\w_]+@[\w_]+$/)

        Hash[[:supplier, :consumer, :carrier].zip(name.split(/[-@]/).map(&:to_sym))]
      end

      def validate_associated_documents
        errors.add(:carrier, 'does not exist') if carrier && !Carrier.manager.key?(carrier)

        if supplier && !graph_config.node_class.manager.key?(supplier)
          errors.add(:supplier, 'does not exist')
        end

        if consumer && !graph_config.node_class.manager.key?(consumer)
          errors.add(:consumer, 'does not exist')
        end
      end
    end

    # ----------------------------------------------------------------------------------------------

    def self.all
      EnergyEdge.all + MoleculeEdge.all
    end
  end
end
