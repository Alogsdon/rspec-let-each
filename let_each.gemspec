require_relative 'lib/let_each/version'

Gem::Specification.new do |spec|
  spec.name          = 'let_each'
  spec.summary       = 'Ergonomic context spawning for RSpec'
  spec.version       = LetEach::VERSION
  spec.authors       = ['Andrew Logsdon']
  spec.license       = 'MIT'
  spec.homepage      = 'https://github.com/Alogsdon/rspec-let-each'
  spec.required_ruby_version = '>= 2.7'

  spec.files         = Dir['lib/**/*.rb', 'LICENSE.txt', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'rspec-core', '>= 3.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
