require 'rails'
require 'mongoid'
require 'elasticsearch'

require 'elastic_model/version'
require 'elastic_model/instrumentation'
require 'elastic_model/callbacks'

# TODO: error out if host is not defined
log = ENV['debug'] ? true : false
$es ||= Elasticsearch::Client.new(:host => 'localhost:19200', :log => log)
