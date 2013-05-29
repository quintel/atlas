# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  # library
  watch('lib/tome.rb')           { "spec" }
  watch(%r{^lib/tome/(.+)\.rb$}) { "spec" }

  # specs
  watch('spec/spec_helper.rb')   { "spec" }
  watch(%r{^spec/.+_spec\.rb$})

  # fixtures
  watch(%r{^spec/fixtures/(.+)}) { "spec" }
end
