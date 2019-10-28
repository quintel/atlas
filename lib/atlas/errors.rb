# frozen_string_literal: true

module Atlas
  # Error class which serves as a base for all errors which occur in Atlas.
  class AtlasError < RuntimeError
    def initialize(*args)
      super(make_message(*args).dup)
    end

    def make_message(msg)
      msg
    end
  end

  # Superclass for errors which occur when calculating the Rubel attributes.
  class CalculationError < AtlasError
  end

  # An error used when an error occurrs during parsing. The parsers classes
  # do not know of the file paths, so the exception is rescused higher up the
  # stack and the relevant information added there.
  class ParserError < AtlasError
    attr_writer :path

    def to_s
      if @path
        "#{super}\n\n" \
        "Occurred in: #{@path.relative_path_from(Atlas.data_dir)}"
      else
        super
      end
    end
  end

  # Raised when an error occurs executing a Rubel query.
  class QueryError < AtlasError
    attr_reader :original

    def initialize(original, query)
      @original = original
      @query    = query
    end

    def backtrace
      @original.backtrace
    end

    def message
      "Error executing query:\n" \
        "#{@original.message}\n" \
        "#{query}\n"
    end

    # The query which failed to execute. If we can find the line which failed,
    # then we place a "margin" to the left of each line so that we can
    # highlight it to the user.
    def query
      return unless @query.is_a?(String)

      if match_number = backtrace.first.match(/\(eval\):(\d+)/)
        line_no = match_number[1].to_i - 1

        @query.lines.map.with_index do |line, index|
          if index == line_no
            ">> | #{line}"
          else
            "   | #{line}"
          end
        end.join
      else
        @query
      end
    end
  end

  # --------------------------------------------------------------------------

  # Internal: Creates a new error class which inherits from AtlasError,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   fail MyError.new(5000, 2500)
  #   # => #<Atlas::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = AtlasError, &block)
    Class.new(superclass) { define_method(:make_message, &block) }
  end

  DocumentNotFoundError =
    error_class do |key, klass = nil|
      name = klass && klass.name.demodulize.humanize.downcase || 'document'

      if key.is_a?(Array)
        "Could not find a #{name} with one of these keys: " +
          "#{key[0..-2].map(&:inspect).join(', ')}, or #{key.last.inspect}"
      else
        "Could not find a #{name} with the key #{key.inspect}"
      end
    end

  ReadOnlyError =
    error_class do
      'Read-only documents may not be saved, updated, or deleted'
    end

  InvalidDocumentError =
    error_class do |document|
      "#{document.class.name.demodulize}(#{document.key.inspect}) was " \
      "not valid: #{document.errors.to_a.join(', ')}"
    end

  InvalidKeyError =
    error_class do |key|
      "Invalid key entered: #{key.inspect}"
    end

  DuplicateKeyError =
    error_class(InvalidKeyError) do |key|
      "Duplicate key found: #{key}"
    end

  MissingAttributeError =
    error_class do |attribute, object|
      "Missing attribute #{attribute} for #{object}"
    end

  IllegalDirectoryError =
    error_class do |path, directory|
      "The given path #{path.to_s.inspect} does not appear to be a " \
      "subdirectory of #{directory.to_s.inspect}"
    end

  NoPathOrKeyError =
    error_class(InvalidKeyError) do |klass|
      "Cannot create a new #{klass.name} without a :path or :key"
    end

  UnknownUnitError =
    error_class do |unit|
      "Invalid unit requested: #{unit.inspect}"
    end

  NonMatchingNodesError =
    error_class(InvalidKeyError) do |node, path, attrs|
      "Cannot specify different #{node} node in the key and attributes: " \
      "got #{path.to_s.inspect} and #{attrs.to_s.inspect}"
    end

  IllegalNestedHashError =
    error_class do |values|
      'Documents may not contain hashes nested inside arrays: ' \
      "#{values.inspect}"
    end

  NoSuchDocumentClassError =
    error_class do |subclass, path|
      "#{path} tried to instantiate a Atlas::#{subclass.to_s.classify}, " \
      "but no such class exists (#{subclass} => #{subclass.classify})"
    end

  MeritRequired =
    error_class do
      'The Merit library must have been loaded before you can ' \
      'call Dataset#load_profile'
    end

  OsmosisRequired =
    error_class do |klass|
      'The Osmosis library must have been loaded before you can ' \
      "use an #{klass.name}"
    end

  # Graph Structure / Topology Errors ----------------------------------------

  InvalidLinkError =
    error_class do |link|
      "#{link.inspect} is not a valid link"
    end

  UnknownLinkTypeError =
    error_class(InvalidLinkError) do |link, type|
      "#{link.inspect} uses unknown link type: #{type.inspect}"
    end

  UnknownLinkNodeError =
    error_class(InvalidLinkError) do |link, key|
      "Unknown node #{key.inspect} in link #{link.inspect}"
    end

  UnknownLinkCarrierError =
    error_class(InvalidLinkError) do |link, carrier|
      "Unknown carrier #{carrier.inspect} in link #{link.inspect}"
    end

  # Rubel Attribute Errors ---------------------------------------------------

  InvalidLookupError =
    error_class(CalculationError) do |keys|
      "Could not perform a lookup with #{keys.inspect}. Give a single key " \
      'to look up a Node, or three keys to look up an edge.'
    end

  UnknownNodeError =
    error_class(InvalidLookupError) do |key|
      "No node exists with the key #{key.inspect}"
    end

  UnknownEdgeError =
    error_class(InvalidLookupError) do |keys|
      "Could not find edge '#{keys.first} -#{keys[1]}-> #{keys.last}'"
    end

  NonNumericQueryError =
    error_class(CalculationError) do |result|
      "Non-numeric query result: #{result.inspect}"
    end

  # CSV Document Errors ------------------------------------------------------

  UnknownCSVRowError =
    error_class do |document, row|
      "No row called #{row.inspect} in #{document.path}"
    end

  UnknownCSVCellError =
    error_class do |document, column|
      "No column called #{column.inspect} in #{document.path}"
    end

  BlankCSVHeaderError =
    error_class(InvalidKeyError) do |path|
      "#{path} contains a cell in the header row which has no value. All " \
      'of the cells in the first row must contain a non-blank value.'
    end

  ExistingCSVHeaderError =
    error_class do |path|
      "Column headers provided although CSV file #{path} already exists"
    end

  # Parser Errors ------------------------------------------------------------

  CannotIdentifyError =
    error_class(ParserError) do |string|
      "Cannot identify this line: #{string}"
    end

  CannotParseError =
    error_class(ParserError) do |string, object|
      "Cannot parse this line: #{string.to_s.inspect} using #{object}."
    end

  InvalidMultilineBlockError =
    error_class(ParserError) do |lines|
      block = lines.map { |line| "  #{line}" }.join("\n")
      preamble = 'Invalid start to a multi-line attribute. There should be ' \
                 "no content after the equals ('=') sign; the value should " \
                 'start on the following line.'

      "#{preamble}\n\n#{block}"
    end
end
