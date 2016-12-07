require 'fileutils'
require 'yaml'
require 'tmpdir'

require 'support/coverage'

ENV['ATLAS_ENV'] = 'test'
require_relative '../lib/atlas'

I18n.config.enforce_available_locales = true

Bundler.require(:test)

require 'support/fixtures'
require 'support/matchers'
require 'support/some_document'
require 'support/graph_helper'

RSpec.configure do |config|
  # Use only the new "expect" syntax.
  config.expect_with(:rspec) { |c| c.syntax = :expect }

  # Tries to find examples / groups with the focus tag, and runs them. If no
  # examples are focues, run everything. Prevents the need to specify
  # `--tag focus` when you only want to run certain examples.
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true

  # Allow adding examples to a filter group with only a symbol.
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  # Use a (safe) copy of spec/fixtures as the data-source.
  config.include Atlas::Spec::Fixtures
end
