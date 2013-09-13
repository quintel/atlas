namespace :debug do
  task :check do
    abort "'rake debug:check' has been replaced. " \
          "You should now run 'rake debug FAST=true'."
  end

  task :graph do
    abort "'rake debug:graph' has been replaced. " \
          "You should now run 'rake debug'."
  end # task :graph

  task debug: :environment do
    dataset = Atlas::Dataset.find(ENV['DATASET'] || :nl)

    if ENV['FAST']
      filters = []
    elsif ENV['FILTER']
      filters = ENV['FILTER'].split(',')
    else
      filters = Atlas::DebugRunner::SECTORS
    end

    graph = Atlas::DebugRunner.new(dataset, 'tmp', filters).run!

    if ENV['CONSOLE']
      require 'pry'
      binding.pry
    end
  end
end # namespace :debug


desc 'Output before and after diagrams of all the subgraphs.'
task debug: ['debug:debug']
