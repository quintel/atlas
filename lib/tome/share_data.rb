module Tome
  # Parses data about edge shares from datasets/$AREA/shares files.
  class ShareData < CSVDocument
    attr_reader :dataset, :file_key

    # Public: Creates a new ShareData instance.
    #
    # dataset  - The corresponding Dataset, whose share data is to be read.
    # file_key - The name of the data file, minus extension.
    #
    # Returns a ShareData.
    def initialize(dataset, file_key)
      @dataset  = dataset
      @file_key = file_key.to_sym

      unless (path = @dataset.path.join("shares/#{ @file_key }.csv")).file?
        raise UnknownShareDataError.new(path)
      end

      super(path)
    end

    # Public: The share value whose name matches +attribute+.
    #
    # For example:
    #
    #   data.get(:gasoline) # => 0.3
    #
    # Returns a Numeric, or raises an error if no such attribute exists in the
    # source file.
    def get(attribute)
      row(attribute)[:share]
    end

    # Public: A human-readable version of the ShareData. Useful for debugging.
    #
    # Returns a string.
    def inspect
      "#<#{ self.class.name } area=#{ @dataset.key } file_key=#{ file_key }>"
    end
  end # ShareData
end # Tome
