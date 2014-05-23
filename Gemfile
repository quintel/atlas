source "https://rubygems.org"

gemspec

gem 'rubel',    ref: 'ad3d44e', github: 'quintel/rubel'
gem 'refinery', ref: '0c14132', github: 'quintel/refinery'

group :development do
  gem 'httparty'
end

group :test do
  gem 'rspec'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
  gem 'simplecov'

  # Switch back to mainline once 2.6.1 is released.
  gem 'shoulda-matchers', '>= 2.6.1.rc1'

  # Growl notifications in Guard.
  gem 'ruby_gntp', require: false
end
