source "https://rubygems.org"

gemspec

group :development do
  gem 'refinery', git: 'git@github.com:quintel/refinery.git', require: false
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
