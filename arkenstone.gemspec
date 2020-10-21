# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arkenstone/version'

Gem::Specification.new do |spec|
  spec.name          = 'arkenstone'
  spec.version       = Arkenstone::VERSION
  spec.authors       = ['Michael Christenson II', 'Steve Young', 'Scott Williams', 'Brett Byler']
  spec.email         = ['m3talsmith@gmail.com']
  spec.description   = 'An ActiveRecord replacement over REST'
  spec.summary       = 'A drop-in replacement for ActiveRecord that performs CRUD operations over RESTful URLs.'
  spec.homepage      = 'https://github.com/m3talsmith/arkenstone'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 12.3','>= 12.3.3'
  spec.add_runtime_dependency 'activesupport', '~> 4.0'

  spec.required_ruby_version = '>= 2.0'
end
