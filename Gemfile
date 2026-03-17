source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

gem 'refinery', ref: '36b8e34', github: 'quintel/refinery'
gem 'rubel',    ref: '9fe7010', github: 'quintel/rubel'

gem "logger", "~> 1.7"
gem "mutex_m", "~> 0.3.0"
gem "bigdecimal", "~> 3.2"
gem "ostruct", "~> 0.6.3"

group :development do
  gem 'httparty'
  gem 'osmosis', ref: '16fac7c', github: 'quintel/osmosis', require: false

  gem 'rubocop', '~> 0.85.0', require: false
  gem 'rubocop-performance',  require: false
  gem 'rubocop-rspec',        require: false
end

group :test do
  gem 'rspec'
  gem 'shoulda-matchers'
  gem 'simplecov'
end
