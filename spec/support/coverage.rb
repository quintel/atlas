require 'simplecov'

SimpleCov.start do
  add_filter('/spec')
  add_filter('/lib/atlas/debug_runner')
  add_filter('/lib/atlas/term')
end

if ENV['CI']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
  Codecov.pass_ci_if_error = true
end
