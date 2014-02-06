require 'spec_helper'

describe ElasticModel::Callbacks do
  context 'persistance' do
    let(:test_class) do
      define_constant('test_class') do
        include Mongoid::Document
        include ElasticModel::Instrumentation
        include ElasticModel::Callbacks
        create_es_index

        field :count, :type => Integer
      end
    end
    let(:test_instance) { test_class.new(:count => 1) }

    context 'create' do
      it 'persists data to elasticsearch after it has persisted to the db' do
        test_instance.save
        res = $es.get :index => test_class.es_index_name, :type => test_class.es_type, :id => test_instance.id
        res['_source']['_id'].should == test_instance.id.to_s
        res['_source']['count'].should == test_instance.count
      end
    end

    context 'update' do
      it 'updates elasticserach document if the document has changed' do
        test_instance.save
        test_instance.count = 2
        test_instance.save
        res = $es.get :index => test_class.es_index_name, :type => test_class.es_type, :id => test_instance.id
        res['_source']['_id'].should == test_instance.id.to_s
        res['_source']['count'].should == test_instance.count
        res['_version'].should == 2
      end

      it 'does not update elasticsearch if the document has not changed' do
        test_instance.save
        test_instance.save
        res = $es.get :index => test_class.es_index_name, :type => test_class.es_type, :id => test_instance.id
        res['_source']['_id'].should == test_instance.id.to_s
        res['_source']['count'].should == test_instance.count
        res['_version'].should == 1
      end
    end

    context 'destroy' do
      it 'destroys elasticsearch document after it destroys it from mongo' do
        test_instance.save
        test_instance.destroy
        expect do
          $es.get :index => test_class.es_index_name, :type => test_class.es_type, :id => test_instance.id
        end.to raise_error(Elasticsearch::Transport::Transport::Errors::NotFound)
      end
    end
  end
end
