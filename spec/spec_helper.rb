Dir["./spec/support/**/*.rb"].each {|f| require f}

require 'simplecov'

SimpleCov.start do
  add_group 'lib', 'lib/'
end

require 'elastic_model'
require 'mocha'
require 'bourne'
require 'elastic_model/matchers'
require 'awesome_print'
require 'pry'

Mongoid.load!('./spec/config/mongoid.yml')

RSpec.configure do |config|
  config.color_enabled = true
  config.include DefineConstantHelpers
  config.mock_with :mocha
end
