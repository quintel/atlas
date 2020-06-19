require 'fileutils'

module Atlas
  module ActiveDocument
    extend ActiveSupport::Concern

    included do
      include Virtus.model
      include ActiveModel::Validations
      include ActiveDocument::Persistence
      include ActiveDocument::Finders
      include ActiveDocument::Naming
      include ActiveDocument::Subclassing
      include ActiveDocument::Last
    end

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
        validates :key, presence: true
      end

      # Public: Creates a new document
      #
      # attributes - A hash of attributes to be set on the document.
      #
      # Returns your new document.
      def initialize(attributes = {})
        path = attributes.delete(:path) || attributes.delete('path')
        key  = attributes.delete(:key)  || attributes.delete('key')

        if path || key
          path ? (self.path = path) : (self.key = key)
          @last_saved_file_path = self.path.dup
        else
          @last_saved_file_path = nil
        end

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
        attributes.merge(comments: comments).delete_if { |_, value| value.nil? }
      end
    end
  end
end
