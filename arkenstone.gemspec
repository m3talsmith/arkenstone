# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'arkenstone/version'

Gem::Specification.new do |spec|
  spec.name          = "arkenstone"
  spec.version       = Arkenstone::VERSION
  spec.authors       = ["Michael Christenson II", "Steve Young", "Scott Williams", "Brett Byler"]
  spec.email         = ["mchristenson@revspringinc.com"]
  spec.description   = "An ActiveRecord replacement over REST"
  spec.summary       = "A drop-in replacement for ActiveRecord that performs CRUD operations over RESTful URLs."
  spec.homepage      = "https://github.com/RevSpringPhoenix/arkenstone"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", '~>10'
  spec.add_runtime_dependency "activesupport", '~> 3.2.0'

  spec.required_ruby_version = '>= 2.0'
end
