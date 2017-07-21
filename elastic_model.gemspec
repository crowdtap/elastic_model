# coding: utf-8
puts __FILE__ if ENV['debug']

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_model/version'

Gem::Specification.new do |spec|
  spec.name          = "elastic_model"
  spec.version       = ElasticModel::VERSION
  spec.authors       = ["Quentin Decock"]
  spec.email         = ["quentind@crowdtap.com"]
  spec.summary       = %q{Lightweight Elasticsearch integration for your Rails models}
  spec.description   = %q{
    Lightweight Elasticsearch integration for your Rails
    models providing:
      - Model callbacks to synchronize your rails models with Elasticsearch
      - Tools to create Elasticsearch indices and mappings for your models
  }
  spec.homepage      = "http://www.github.com/crowdtap/elastic_model/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "mocha", "0.9.8"
  spec.add_development_dependency "bourne"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "pry"

  spec.add_runtime_dependency "mongoid"
  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "bson_ext"
  spec.add_runtime_dependency "elasticsearch", "~> 1.0.2"
  spec.add_runtime_dependency "rails", "~> 3.2"
end
