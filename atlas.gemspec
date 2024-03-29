lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'atlas/version'

Gem::Specification.new do |gem|
  gem.name          = 'atlas'
  gem.version       = Atlas::VERSION
  gem.authors       = ["Dennis Schoenmakers, Anthony Williams"]
  gem.email         = ["dennis.schoenmakers@quintel.com,
                        anthony.williams@quintel.com"]
  gem.description   = %q{Data for ETM}
  gem.summary       = %q{}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'activemodel',   '>= 7'
  gem.add_dependency 'activesupport', '>= 7'
  gem.add_dependency 'gpgme',         '~> 2.0'
  gem.add_dependency 'turbine-graph', '>= 0.1'
  gem.add_dependency 'virtus',        '~> 1.0'
  gem.add_dependency 'csv',           '>= 3'

  gem.add_development_dependency 'rake', '>= 10.0.3'
  gem.add_development_dependency 'pry',  '>= 0.9.12'
  gem.add_development_dependency 'term-ansicolor', '>= 1.2.0'
  gem.add_development_dependency 'ruby-progressbar'

end
