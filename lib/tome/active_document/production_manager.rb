module Tome
  module ActiveDocument
    # A Manager which loads documents but sets extra attribute values by
    # loading the exported CSV files. This is used in "production"
    # environments such as ETEngine when running Rubel queries and Refinery
    # would be prohibitively slow.
    class ProductionManager < Manager
      # Public: Creates a new manager for the given document +klass+.
      #
      # klass    - The ActiveDocument class whose files are read by the
      #            Manager instance.
      #
      # area     - The area code whose exported data will be loaded.
      #
      # register - Tells the Manager whether to register itself with the
      #            class. This should be set to false if you want to create
      #            managers on-the-fly, but note that its cache will not be
      #            expired if the ETSource data directory is changed.
      #
      # Returns a Manager::Production.
      def initialize(klass, area)
        super(klass, false)
        @area = area.to_sym
      end

      #######
      private
      #######

      # Internal: Loads a document from disk by its +key+.
      #
      # Returns the ActiveDocument.
      def load(key)
        super.tap { |doc| doc.attributes = exported_data_for(doc.key) }
      end

      # Internal: Returns the static, exported values for the document
      # matching the given key.
      #
      # key - The document key whose exported values are to be looked up.
      #
      # Returns a hash.
      def exported_data_for(key)
        exported_data[key] || Hash.new
      end

      # Internal: Loads the CSV of exported values for the class being
      # managed.
      #
      # Returns a hash where each key is the key of one of the documents, and
      # each value is a hash of values to be set on the document.
      def exported_data
        @export ||= YAML.load_file(
          Tome.data_dir.join("static/#{ @area }.yml")
        )[ @klass.name.demodulize.underscore.pluralize.to_sym ]
      end
    end # ProductionManager
  end # ActiveDocument
end # Tome
