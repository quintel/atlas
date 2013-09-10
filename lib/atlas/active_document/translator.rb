module Atlas
  module ActiveDocument
    module Translator

      # Public: Returns a CSV formatted version of this ActiveDocument
      #
      def to_csv
        Atlas::HashToCSVParser.new(to_hash).to_csv
      end

      # Public: Returns a AD formatted version of this ActiveDocument
      #
      def to_text
        Atlas::HashToTextParser.new(to_hash).to_text
      end

    end # Translator
  end # ActiveDocument
end # Atlas
