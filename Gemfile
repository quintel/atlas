source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

gem 'rubel',    ref: 'ad3d44e', github: 'quintel/rubel'
gem 'refinery', ref: '72eacf8', github: 'quintel/refinery'

group :development do
  gem 'httparty'
  gem 'osmosis', github: 'quintel/osmosis', require: false

  gem 'rubocop', '~> 0.85.0', require: false
  gem 'rubocop-performance',  require: false
  gem 'rubocop-rspec',        require: false
end

group :test do
  gem 'rspec'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'simplecov'
  gem 'codecov', require: false

  # Switch back to mainline once 2.6.1 is released.
  gem 'shoulda-matchers', '>= 2.6.1.rc1'

  # Growl notifications in Guard.
  gem 'ruby_gntp', require: false
end
