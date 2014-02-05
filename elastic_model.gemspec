# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_model/version'

Gem::Specification.new do |spec|
  spec.name          = "elastic_model"
  spec.version       = ElasticModel::VERSION
  spec.authors       = ["Quentin Decock"]
  spec.email         = ["quentind@crowdtap.com"]
  spec.summary       = %q{Lightweight Elasticsearch integration for your Rails models}
  spec.description   = %q{Lightweight Elasticsearch integration for your Rails models}
  spec.homepage      = "http://www.github.com/crowdtap/elastic_model/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
