source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

gem 'refinery', ref: 'c308c6d', github: 'quintel/refinery' #TODO: update once merged to master
gem 'rubel',    ref: '32ae1ea', github: 'quintel/rubel' #TODO: update once merged to master

gem "logger", "~> 1.7"
gem "mutex_m", "~> 0.3.0"
gem "bigdecimal", "~> 3.2"
gem "ostruct", "~> 0.6.3"

group :development do
  gem 'httparty'
  gem 'osmosis', ref: '853a6e8', github: 'quintel/osmosis', require: false #TODO: update once merged to master

  gem 'rubocop', '~> 0.85.0', require: false
  gem 'rubocop-performance',  require: false
  gem 'rubocop-rspec',        require: false
end

group :test do
  gem 'rspec'
  gem 'shoulda-matchers'
  gem 'simplecov'
end
