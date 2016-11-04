source "https://rubygems.org"

gemspec

gem 'rubel',    ref: 'ad3d44e', github: 'quintel/rubel'
gem 'refinery', ref: '636686c', github: 'quintel/refinery'

group :development do
  gem 'httparty'
  gem 'osmosis', github: 'quintel/osmosis', require: false
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
