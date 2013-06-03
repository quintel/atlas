module Tome

  # Error class which serves as a base for all errors which occur in Tome.
  class TomeError < RuntimeError
    def initialize(*args) ; super(make_message(*args)) ; end
    def make_message(msg) ; msg ; end
  end

  # Superclass for errors which occur when calculating the Rubel attributes.
  class CalculationError < TomeError
  end

  # Internal: Creates a new error class which inherits from TomeError,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   raise MyError.new(5000, 2500)
  #   # => #<Tome::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = TomeError, &block)
    Class.new(superclass) { define_method(:make_message, &block) }
  end

  DocumentNotFoundError = error_class do |key, klass = nil|
    name = klass && klass.name.demodulize.humanize.downcase || 'document'
    "Could not find a #{ name } with the key #{ key.inspect }"
  end

  InvalidDocumentError = error_class do |document|
    "#{ document.class.name.demodulize }(#{ document.key.inspect }) was " \
    "not valid: #{ document.errors.to_a.join(", ") }"
  end

  InvalidKeyError = error_class do |key|
    "Invalid key entered: #{ key.inspect }"
  end

  DuplicateKeyError = error_class(InvalidKeyError) do |key|
    "Duplicate key found: #{ key }"
  end

  MissingAttributeError = error_class do |attribute, object|
    "Missing attribute #{ attribute } for #{ object }"
  end

  IllegalDirectoryError = error_class do |path, directory|
    "The given path #{ path.to_s.inspect } does not appear to be a " \
    "subdirectory of #{ directory.to_s.inspect }"
  end

  NoPathOrKeyError = error_class(InvalidKeyError) do |klass|
    "Cannot create a new #{ klass.name } without a :path or :key"
  end

  UnknownUnitError = error_class do |unit|
    "Invalid unit requested: #{ unit.inspect }"
  end

  NonMatchingNodesError = error_class(InvalidKeyError) do |node, path, attrs|
    "Cannot specify different #{ node } node in the key and attributes: " \
    "got #{ path.to_s.inspect } and #{ attrs.to_s.inspect }"
  end

  IllegalNestedHashError = error_class do |values|
    "Documents may not contain hashes nested inside arrays: " \
    "#{ values.inspect }"
  end

  # Graph Structure / Topology Errors ----------------------------------------

  InvalidLinkError = error_class do |link|
    "#{ link.inspect } is not a valid link"
  end

  UnknownLinkTypeError = error_class(InvalidLinkError) do |link, type|
    "#{ link.inspect } uses unknown link type: #{ type.inspect }"
  end

  UnknownLinkNodeError = error_class(InvalidLinkError) do |link, key|
    "Unknown node #{ key.inspect } in link #{ link.inspect }"
  end

  UnknownLinkCarrierError = error_class(InvalidLinkError) do |link, carrier|
    "Unknown carrier #{ carrier.inspect } in link #{ link.inspect }"
  end

  # Rubel Attribute Errors ---------------------------------------------------

  InvalidLookupError = error_class(CalculationError) do |keys|
    "Could not perform a lookup with #{ keys.inspect }. Give a single key " \
    "to look up a Node, or three keys to look up an edge."
  end

  UnknownNodeError = error_class(InvalidLookupError) do |key|
    "No node exists with the key #{ key.inspect }"
  end

  UnknownEdgeError = error_class(InvalidLookupError) do |keys|
    "Could not find edge '#{ keys.first } -#{ keys[1] }-> #{ keys.last }'"
  end

  NonNumericQueryError = error_class(CalculationError) do |result|
    "Non-numeric query result: #{ result.inspect }"
  end

  # CSV Document Errors ------------------------------------------------------

  UnknownCSVRowError = error_class do |document, row|
    "No row called #{ row.inspect } in #{ document.path }"
  end

  UnknownCSVCellError = error_class do |document, column|
    "No column called #{ column.inspect } in #{ document.path }"
  end

  BlankCSVHeaderError = error_class(InvalidKeyError) do |path|
    "#{ path } contains a cell in the header row which has no value. All " \
    "of the cells in the first row must contain a non-blank value."
  end

end # Tome
