# frozen_string_literal: true

module Atlas
  class Dataset
    # Contains one or more `CurveSet`s belonging to a `Dataset`.
    class CurveSetCollection
      include Enumerable

      # Public: Given a path to a directory containing zero or more curve set
      # directories, instantiates the CurveSet instances and returns a
      # collection.
      def self.at_path(dir)
        new(dir.children.select(&:directory?).map do |path|
          CurveSet.new(path)
        end)
      end

      # Public: Creates a new collection of `CurveSet`s.
      #
      # sets - An array of zero or more CurveSet instances.
      #
      # Returns a CurveSetCollection.
      def initialize(sets)
        @sets =
          Array(sets).each_with_object({}) do |set, map|
            map[set.name] = set
          end
      end

      # Public: Returns if a curve set matching `name` exists.
      def key?(name)
        @sets.key?(name.to_s)
      end

      # Public: Returns the curve set matching `name` or nil if the set does not
      # exist.
      def get(name)
        @sets[name.to_s]
      end

      alias_method :[], :get

      # Public: Returns all of the CurveSets in an array.
      def to_a
        @sets.values
      end

      # Public: Yields each CurveSet in the collection.
      def each
        return enum_for(:each) unless block_given?

        @sets.each { |_, set| yield(set) }
      end

      def length
        @sets.length
      end

      def inspect
        "#<#{self.class} (#{@sets.keys.join(', ')})>"
      end
    end
  end
end
