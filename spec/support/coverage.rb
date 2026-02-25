require 'simplecov'

SimpleCov.start do
  add_filter('/spec')
  add_filter('/lib/atlas/debug_runner')
  add_filter('/lib/atlas/term')
end
