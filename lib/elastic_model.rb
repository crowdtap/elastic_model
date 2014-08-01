require 'rails'
require 'mongoid'
require 'elasticsearch'

require 'elastic_model/version'
require 'elastic_model/instrumentation'
require 'elastic_model/callbacks'
require 'elastic_model/exceptions'

# TODO: error out if host is not defined
log = ENV['debug'] ? true : false
$es ||= Elasticsearch::Client.new(:host => ENV['BOXEN_ELASTICSEARCH_URL'] || 'localhost:9200', :log => log)
