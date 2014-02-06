Dir["./spec/support/**/*.rb"].each {|f| require f}

require 'elastic_model'
require 'mocha'

RSpec.configure do |config|
  config.color_enabled = true
  config.include DefineConstantHelpers
  config.mock_with :mocha
end
