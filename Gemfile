source "https://rubygems.org"

gemspec

gem 'refinery', ref: '9cf6a73', github: 'quintel/refinery'
gem 'rubel',    '~> 0.1.0',     github: 'quintel/rubel'

group :development do
  gem 'httparty'
end

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
