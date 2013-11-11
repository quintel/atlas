# A task which sets up Atlas for use in Rake tasks.
task :environment, [:data_dir] do |_, args|
  $LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/..'))

  require 'fileutils'
  require 'atlas'
  require 'term/ansicolor'
  require 'active_support/core_ext/hash/indifferent_access'

  Atlas.data_dir = args.data_dir || '../etsource'
end # environment
