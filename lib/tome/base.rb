module Tome
  # Parent directory where all the 'models' live
  # such as inputs, gqueries etc.
  def self.root
    @root ||= Pathname.new(__FILE__).dirname.expand_path.parent.parent
  end

  # Public: Path to the directory in which ActiveDocument files typically
  # reside. This will normally have subfolders like datasets/, nodes/, etc.
  #
  # Returns a Pathname.
  def self.data_dir
    @data_dir ||= root.join('data')
  end

  # Public: Sets the path to the direction in which the data files reside.
  #
  # When using Tome in an application, the +data_dir+ should be set *once*
  # using the path to the real data. If you need to temporarily alter the
  # +data_dir+ (for example, in tests), use +with_data_dir+ instead.
  #
  # Returns the path provided.
  def self.data_dir=(path)
    path = path.is_a?(Pathname) ? path : Pathname.new(path.to_s)

    if path.relative?
      path = Tome.root.join(path)
    end

    if path != @data_dir
      @data_dir = path
      ActiveDocument::Manager.clear_all!
    end
  end

  # Public: Wrap around a block of code to work with a temporarily altered
  # +data_dir+ setting.
  #
  # directory - The new, but temporary, data_dir path.
  #
  # Returns the result of your block.
  def self.with_data_dir(directory)
    previous      = data_dir
    self.data_dir = directory

    yield
  ensure
    self.data_dir = previous
  end

  # Internal: Loads an optional Gem dependency. Used to limit what Tome loads
  # in production environments.
  #
  # name - The name of the library to load.
  #
  # Returns nothing.
  def self.load_library(name)
    unless defined?(::Bundler)
      require 'bundler'
      Bundler.setup((ENV['TOME_ENV'] || :development).to_sym)
    end

    require name
  rescue LoadError => ex
    raise LoadError.new("#{ ex.message }. This is an optional dependency " \
                        "which is not available in production.")
  end
end # Tome
