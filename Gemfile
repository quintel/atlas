source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gemspec

gem 'refinery', ref: '2878111', github: 'quintel/refinery'
gem 'rubel',    ref: 'ad3d44e', github: 'quintel/rubel'

group :development do
  gem 'httparty'
  gem 'osmosis', github: 'quintel/osmosis', require: false

  gem 'rubocop', '~> 0.85.0', require: false
  gem 'rubocop-performance',  require: false
  gem 'rubocop-rspec',        require: false
end

group :test do
  gem 'codecov', require: false
  gem 'rspec'
  gem 'rspec_junit_formatter'
  gem 'shoulda-matchers'
  gem 'simplecov'
end
