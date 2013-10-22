source "https://rubygems.org"

gemspec

gem 'refinery', ref: '9630d75', git: 'git@github.com:quintel/refinery.git'

group :test do
  gem 'rspec'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'simplecov'
  gem 'shoulda-matchers'

  # Growl notifications in Guard.
  gem 'ruby_gntp', require: false
end
