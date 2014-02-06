require 'rails'
require 'mongoid'
require 'elasticsearch'

require 'elastic_model/instrumentation'
require 'elastic_model/callbacks'

# TODO: error out if host is not defined
log = ENV['debug'] ? true : false
$es ||= Elasticsearch::Client.new(:host => 'localhost:9200', :log => log)
