# frozen_string_literal: true

namespace :debug do
  task :check do
    abort "'rake debug:check' has been replaced. " \
          "You should now run 'rake debug FAST=true'."
  end

  task :graph do
    abort "'rake debug:graph' has been replaced. " \
          "You should now run 'rake debug'."
  end

  task debug: :environment do
    env     = Hash[ENV.map { |key, val| [key.upcase, val] }]
    dataset = Atlas::Dataset.find(env['DATASET'] || :nl)

    filters =
      if env['FAST']
        []
      elsif env['FILTER']
        env['FILTER'].split(',')
      else
        Atlas::DebugRunner::SECTORS
      end

    graph = Atlas::DebugRunner.new(dataset, 'tmp', filters).run!

    if env['CONSOLE']
      require 'pry'
      binding.pry
    end
  end
end

desc 'Output before and after diagrams of all the subgraphs.'
task debug: ['debug:debug']
