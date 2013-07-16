# More info at https://github.com/guard/guard#readme

guard 'rspec' do
  # library
  watch('lib/atlas.rb')           { "spec" }
  watch(%r{^lib/atlas/(.+)\.rb$}) { |m| "spec/atlas/#{m[1]}_spec.rb" }

  # specs
  watch('spec/spec_helper.rb')   { "spec" }
  watch(%r{^spec/.+_spec\.rb$})

  # fixtures
  watch(%r{^spec/fixtures/(.+)}) { "spec" }
end
