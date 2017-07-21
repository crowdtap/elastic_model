require 'rails'
require 'mongoid'
require 'elasticsearch'
require 'elasticsearch/api'
require 'multi_json'
require 'faraday'

require 'elastic_model/version'
require 'elastic_model/instrumentation'
require 'elastic_model/callbacks'

# TODO: error out if host is not defined
#log = ENV['debug'] ? true : false

class ElasticLoggingClient
  include Elasticsearch::API

  CONNECTION = ::Faraday::Connection.new({ url: ENV['BOXEN_ELASTICSEARCH_URL'] || 'localhost:9200' })

  def perform_request(method, path, params, body)
    Rails.logger.info "ELASTICSEARCH QUERY --> #{method.upcase} #{path} #{params} #{body}"

    CONNECTION.run_request(
      method.downcase.to_sym,
      path,
      (body ? MultiJson.dump(body) : nil),
      { 'Content-Type' => 'application/json' }
    )
  end
end

#$es ||= Elasticsearch::Client.new(:host => , :log => log)
$es ||= ElasticLoggingClient.new
