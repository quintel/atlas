module Atlas
  module ActiveDocument
    # A Manager which loads documents but sets extra attribute values by
    # loading the exported CSV files. This is used in "production"
    # environments such as ETEngine when running Rubel queries and Refinery
    # would be prohibitively slow.
    class ProductionManager < Manager
      # Public: Creates a new manager for the given document +klass+.
      #
      # klass - The ActiveDocument class whose files are read by the Manager.
      #
      # data  - Production data for the nodes (normally containing demands
      #         calculated with queries or by Refinery)
      #
      # Returns a Manager::Production.
      def initialize(klass, data)
        super(klass, false)
        @data = data
      end

      # Production-mode documents may not be changed.
      %w( delete write delete_path ).each do |method|
        class_eval <<-RUBY, __FILE__, __LINE__ + 1
          def #{ method }(*)
            raise ReadOnlyError.new
          end
        RUBY
      end

      private

      # Internal: Returns the static, exported values for the document
      # matching the given key.
      #
      # key - The document key whose exported values are to be looked up.
      #
      # Returns a hash.
      def exported_data_for(key)
        @data[key] || {}
      end

      # Internal: Given a document path or key, retrieves the attributes for
      # the document
      #
      # path - Path to the document file.
      # key  - The unique key which identifies the document.
      #
      # Returns a hash.
      def load_attributes(path, key)
        exported_data_for(key)
      end
    end
  end
end
