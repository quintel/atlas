# A task which sets up Tome for use in Rake tasks.
task :environment, [:data_dir] do |_, args|
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

  require 'fileutils'
  require 'tome'
  require 'term/ansicolor'
  require 'active_support/core_ext/hash/indifferent_access'

  Tome.data_dir = dir(args.data_dir || '../etsource/data')
end # environment
