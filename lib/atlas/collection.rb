module Atlas
  # Contains ActiveDocuments, providing a nice way to look up specific
  # documents. It caches the keys of each document after the first call to
  # +find+ to ensure fast lookup. This means that if the key of a document
  # changes, you need to create a new collection. This is simplified for you
  # with +refresh+.
  class Collection < SimpleDelegator

    # Public: Given a +key+, returns the document with the matching key.
    #
    # key - The key to look for.
    #
    # Returns the element from the collection, or nil if none matched.
    def find(key)
      table[key.to_sym] ||
        fail(DocumentNotFoundError.new(key, document_class))
    end

    # Public: Tries each of the +keys+ in turn, until a document is found
    # which matches one.
    #
    # keys - One or more document keys.
    #
    # Returns the document from the dollection, or nil if none matched.
    def fetch(*keys)
      (key = keys.flatten.find { |k| key?(k) }) && find(key) ||
        fail(DocumentNotFoundError.new(keys, document_class))
    end

    # Public: Given a +key+, returns if a document with that key is contained
    # in the collection.
    #
    # key - The key to look for.
    #
    # Returns true or false.
    def key?(key)
      table.key?(key)
    end

    # Public: A new copy of the collection without the key cache; this will
    # make +find+ work if one or more document keys have been changed.
    #
    # Returns a Collection.
    def refresh
      self.class.new(__getobj__)
    end

    # Public: A human-readable version of the collection.
    #
    # Returns a string.
    def inspect
      "#<#{ self.class.name } (#{ length } x #{ document_class.name })>"
    end

    private

    # Internal: Builds a table of document keys and the documents. Memoizes
    # the result after the first call.
    #
    # Returns a Hash.
    def table
      @table ||= __getobj__.each_with_object(Hash.new) do |document, table|
        table[document.key] = document
      end
    end

    # Internal: Tries to determine what type of document is stored in the
    # collection.
    #
    # Returns an ActiveDocument class, or nil/false.
    def document_class
      table.any? &&
       (klass = table.first.last.class) &&
        klass.topmost_document_class
    end

  end
end
