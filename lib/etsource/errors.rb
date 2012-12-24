module ETSource
  # Error class which serves as a base for all errors which occur in ETSource.
  ETSourceError = Class.new(StandardError)

  # Internal: Creates a new error class which inherits from ETSourceError,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   raise MyError.new(5000, 2500)
  #   # => #<ETSource::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = ETSourceError, &block)
    Class.new(superclass) do
      def initialize(*args) ; super(make_message(*args)) ; end
      define_method(:make_message, &block)
    end
  end

  # Added a node to a graph, when one already exists with the same key.
  MissingAttributeError = error_class do |attribute, self|
    "Missing mandatory #{ attritute } for #{ self.to_s }."
  end
end