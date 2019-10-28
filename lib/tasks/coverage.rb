# frozen_string_literal: true

desc 'Generates code coverage rapport'
task :coverage do
  ENV['COVERAGE'] = 'true'
  exec 'bundle exec rspec'
end
