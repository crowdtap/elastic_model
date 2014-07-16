Dir["./spec/support/**/*.rb"].each {|f| require f}

require 'elastic_model'
require 'mocha'
require 'bourne'
require 'elastic_model/matchers'

Mongoid.load!('./spec/config/mongoid.yml')

RSpec.configure do |config|
  config.color = true
  config.include DefineConstantHelpers
  config.mock_with :mocha
  config.expect_with :rspec do |c|
    c.syntax = [:expect, :should]
  end
end
