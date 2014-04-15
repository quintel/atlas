source "https://rubygems.org"

gemspec

gem 'refinery', ref: 'f29ead1', github: 'quintel/refinery'

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
  gem 'shoulda-matchers',
    github: 'antw/shoulda-matchers', ref: 'fix-ar-matcher-inclusion'

  # Growl notifications in Guard.
  gem 'ruby_gntp', require: false
end
