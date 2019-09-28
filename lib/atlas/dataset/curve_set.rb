# frozen_string_literal: true

module Atlas
  class Dataset
    # Describes a directory containing one or more subdirectories, each of which
    # contain curves which may be swapped out for one another.
    #
    # For example, given directories:
    #
    #    - heat
    #      - variant_one
    #        - curve_one.csv
    #        - curve_two.csv
    #      - variant_two
    #        - curve_one.csv
    #        - curve_two.csv
    #
    # The `CurveSet` is called "heat", and has two `Variant`s, each containing
    # a curve_one.csv and curve_two.csv.
    class CurveSet
      # Public: Pathname to the curve set.
      attr_reader :path

      # Public: Read the curve set from `path`.
      def initialize(path)
        @path = path
      end

      def name
        @path.basename.to_s
      end

      # Public: Returns whether the set contains a variant with the given name.
      def variant?(name)
        variants.key?(name.to_s)
      end

      # Public: Returns the `Variant` matching `name`, or nil if no such variant
      # exists.
      def variant(name)
        variants[name.to_s]
      end

      # Public: Returns the `Variant`s in an array.
      def to_a
        variants.values
      end

      def inspect
        "#<#{self.class} #{name} (#{variants.keys.join(', ')})>"
      end

      private

      def variants
        @variants ||=
          @path.children.select(&:directory?)
            .each_with_object({}) do |child, map|
              variant = Variant.new(child)
              map[variant.name] = variant
            end
      end

      # Describes a single variant of the CurveSet. Contains curves which may be
      # swapped out for those of any other variant belonging to the same set.
      class Variant
        # Public: Pathname to the variant.
        attr_reader :path

        def initialize(path)
          @path = path
        end

        def name
          @path.basename.to_s
        end

        def length
          path.children.count { |child| child.file? && child.extname == '.csv' }
        end

        def curve?(name)
          curve_path(name).file?
        end

        # Public: The sanitized path to a curve based on its name.
        #
        # Returns a Pathname.
        def curve_path(name)
          @path.join("#{Pathname.new(name).basename}.csv")
        end

        # Public: Loads the named curve.
        #
        # Raises a Merit::MissingLoadProfileError if the file does not exist, or
        # Atlas::MeritRequired if the Merit library has not been loaded.
        #
        # Returns a Merit::Curve.
        def curve(name)
          Util.load_curve(curve_path(name))
        end

        def inspect
          "<#{self.class} #{name} (#{length} curves)>"
        end
      end
    end
  end
end
