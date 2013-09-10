require 'fileutils'

module Atlas
  module ActiveDocument
    def self.included(base)
      base.class_eval do
        include Virtus
        include ActiveModel::Validations
        include ActiveDocument::Persistence
        include ActiveDocument::Translator
        include ActiveDocument::Finders
        include ActiveDocument::Naming
        include ActiveDocument::Subclassing
        include ActiveDocument::Last
      end
    end

    # Public: The file extension. You can customise this in subclasses.
    #
    # Returns a String.
    FILE_SUFFIX = 'ad'

    # Public: Optional comments available on all documents and the queries
    # that are used to store the query-dependant properties.
    #
    # Returns a String, Hash or nil.
    attr_accessor :comments, :queries

    # Contains the methods which are available on instances of ActiveDocument
    # classes. This has to be a separate module so that we can ensure that
    # Virtus' +initialize+ method is added before ActiveDocument's.
    module Last
      extend ActiveSupport::Concern

      included do
        validate :validate_sets, if: ->{ respond_to?(:sets) && ! sets.nil? }
      end

      # Public: Creates a new document
      #
      # attributes - A hash of attributes to be set on the document. You must
      #              at least provide a :path or :key attribute which is used
      #              to name the document.
      #
      # Returns your new document.
      def initialize(attributes)
        path = attributes.delete(:path)
        key  = attributes.delete(:key)

        fail NoPathOrKeyError.new(self.class) if path.nil? && key.nil?

        path ? (self.path = path) : (self.key = key)
        @last_saved_file_path = self.path.dup

        super(attributes)

        @queries ||= {}
      end

      # Public: A human-readable version of the document.
      #
      # Returns a String.
      def to_s
        "#<#{self.class}: #{key}>"
      end

      alias_method :inspect, :to_s

      # Public: Creates a hash containing the document's attributes, omitting
      # those whose values are nil.
      #
      # Returns a Hash.
      def to_hash
        attributes
          .merge(comments: comments)
          .merge(queries: queries)
          .reject { |_, value| value.nil? }
      end

      #######
      private
      #######

      # Internal: When the document class has a "sets" method, the value of
      # the "sets" attribute indicates which attribute has a value calculated
      # by a query. It should therefore not have a value from the user.
      #
      # Returns nothing.
      def validate_sets
        attribute = sets.to_sym

        if respond_to?(attribute) && ! public_send(attribute).nil?
          errors.add(sets.to_sym, 'may not have a value since it will be ' \
                                  'set by a query')
        end
      end

    end # Last
  end # ActiveDocument
end # Atlas
