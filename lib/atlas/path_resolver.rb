# frozen_string_literal: true

module Atlas
  # PathResolver allows you to provide one or two directories, and lookup files within them.
  #
  # * fallback_dir  - This directory is used for most operations. It defines which files exist, what
  #                   are the subdirectories, what is the basename, etc.
  #
  # * preferred_dir - For some operations, a file with the same basename may exist in both the
  #                   fallback and preferred directories (for example, when calling `join`). When
  #                   this is the case, the path to the file in the preferred directory is used.
  #
  # This class is used by Derived datasets when the dataset may define a customised version of a
  # file provided by the parent dataset, and also may not. The class may be used to find the correct
  # file to use.
  #
  # For some simple operations, a resolver may be used in place of a Pathname. However, as it only
  # provides a small subset of Pathname features, it cannot act as a substitute when you would rely
  # on the semantics of `Pathname#to_s` or `Pathname#to_path`.
  #
  #   # This does not work, because `Pathname.glob` expects a string containing a single path.
  #   Pathname.glob(PathResolver.create('one', 'two'))
  class PathResolver
    include Comparable

    # Public: Creates a PathResolver for the given directory or directories.
    #
    # When only a single path is provided, a PathResolver is returned. When two paths are given, the
    # first is considered a "fallback" path, with paths to the second "preferred" directory given
    # preference. In these cases, a PathResolver::WithFallback is returned instead.
    def self.create(preferred_dir, fallback_dir = nil)
      fallback_dir.nil? ? new(preferred_dir) : WithFallback.new(preferred_dir, fallback_dir)
    end

    delegate(
      :basename,
      :directory?,
      :exist?,
      :extname,
      :file?,
      :to_path,
      :to_s,
      to: :@path
    )

    def initialize(path)
      @path = Pathname.new(path)
    end

    def inspect
      "#<#{self.class.name}:#{@path}>"
    end

    def children(*args)
      @path.children(*args).map { |child| self.class.new(child) }
    end

    def glob(*args)
      @path.glob(*args).map { |child| self.class.new(child) }
    end

    def join(basename)
      self.class.new(resolve(basename))
    end

    def resolve(basename)
      @path.join(basename)
    end

    def ==(other)
      other.to_s == to_s
    end

    def <=>(other)
      to_s <=> other.to_s
    end

    # Compatible with PathResolver, allows providing two directories instead of one, with the second
    # "preferred" given preference over paths from the "fallback".
    class WithFallback
      include Comparable

      attr_reader :preferred
      attr_reader :fallback

      def initialize(preferred, fallback)
        @preferred = Pathname.new(preferred)
        @fallback = Pathname.new(fallback)
      end

      def inspect
        %(#<#{self.class.name} preferred="#{@preferred}" fallback="#{@fallback}">)
      end

      def to_s
        @preferred.exist? ? @preferred.to_s : @fallback.to_s
      end

      def ==(other)
        other.is_a?(self.class) && @fallback == other.fallback && @preferred == other.preferred
      end

      def <=>(other)
        to_s <=> other.to_s
      end

      # Public: Create a Pathname to the file at `basename`.
      #
      # If the file exists in the preferred directory, this path is returned, otherwise the path to
      # the file in the fallback is returned.
      #
      # Returns a Pathname.
      def resolve(basename)
        if (preferred_path = @preferred.join(basename)).exist?
          preferred_path
        else
          @fallback.join(basename)
        end
      end

      # Public: Returns an array of children in the directories.
      #
      # Basenames found in either directory will be included. When a name is a file, the value will be
      # a Pathname, preferentially matching a file in the preferred dir, falling back to the fallback
      # dir when needed. When the basename is a directory, another FallbackPaths will be the value.
      #
      # Returns an array of Pathnames and FallbackPaths.
      def children
        dirs = {}
        files = {}

        [@preferred, @fallback].each do |dir|
          next unless dir.exist?

          dir.children.each do |child|
            if child.directory?
              (dirs[child.basename.to_s] ||= []).push(child)
            else
              files[child.basename.to_s] ||= child
            end
          end
        end

        dirs.each_value.map { |paths| PathResolver.create(*paths) } +
          files.each_value.map { |path| PathResolver.new(path) }
      end

      # Public: Combines the current path with a new basename.
      #
      # There are three possibilities depending on the given basename:
      #
      # 1. When the basename matches an entry in the fallback or preferred directory, and the match
      #    is a sub-directory, a new FallbackPaths is returned combining the two paths.
      #
      # 2. If a matching file exists in the preferred directory, a Pathname is returned to the file.
      #
      # 3. Otherwise, a Pathname to the file in the fallback directory is returned.
      #
      # Returns a FallbackPaths or Pathname.
      def join(basename)
        fallback_path = @fallback.join(basename)
        preferred_path = @preferred.join(basename)

        if fallback_path.directory? && preferred_path.directory?
          return self.class.new(preferred_path, fallback_path)
        end

        PathResolver.create(preferred_path.exist? ? preferred_path : fallback_path)
      end

      # Public: See `Pathname#glob`.
      #
      # Where both directories have a child with an identical path relative to the directory, only
      # the entry belonging to the preferred directory is included.
      #
      # Returns an array of Pathnames.
      def glob(pattern)
        paths = {}

        @fallback.glob(pattern).each do |entry|
          paths[entry.relative_path_from(@fallback).to_s] = entry
        end

        @preferred.glob(pattern).each do |entry|
          paths[entry.relative_path_from(@preferred).to_s] = entry
        end

        paths.values
      end

      def basename
        @fallback.basename
      end

      def extname
        @fallback.extname
      end

      # Public: Does the entry exist on disk?
      def exist?
        either?(:exist?)
      end

      # Public: Returns if one of the paths exist and is a directory.
      def directory?
        either?(:directory?)
      end

      # Public: Returns if one of the paths exist and is a file.
      def file?
        either?(:file?)
      end

      def to_path
        raise NotImplementedError, "to_path is not supported on #{self.class.name}"
      end

      private

      def either?(predicate)
        @fallback.exist? && @fallback.public_send(predicate) ||
          @preferred.exist? && @preferred.public_send(predicate)
      end
    end
  end
end
