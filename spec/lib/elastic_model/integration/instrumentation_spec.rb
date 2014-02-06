require 'spec_helper'

describe ElasticModel::Instrumentation do
  around :each do |test|
    if $es.indices.exists index: 'test_test_classes'
      $es.indices.delete index: 'test_test_classes'
    end
    test.run
    if $es.indices.exists index: 'test_test_classes'
      $es.indices.delete index: 'test_test_classes'
    end
  end

  let(:test_class) do
    define_constant('test_class') do
      include Mongoid::Document
      include ElasticModel::Instrumentation
    end
  end

  describe '.create_es_index' do
    before do
      test_class.class_eval do
        es_index_options :settings => {
          :index => {
            :number_of_shards => 1,
            :number_of_replicas => 0
          }
        }
      end
    end

    it 'creates index when not existing' do
      test_class.create_es_index

      settings = $es.indices.get_settings
      settings[test_class.es_index_name]["settings"]["index.number_of_replicas"].to_i.should == 0
      settings[test_class.es_index_name]["settings"]["index.number_of_shards"].to_i.should == 1
    end

    it 'does not raise error when index is already existing' do
      test_class.create_es_index
      expect { test_class.create_es_index }.not_to raise_error
    end
  end

  context 'when mapping is not existing yet' do
    before do
      test_class.class_eval do
        mapping_for :text_field,         { :type => 'string', :index => 'not_analyzed' }
        mapping_for :integer_field,      { :type => 'integer' }
        mapping_for :indexed_text_field, { :type => 'string', :analyzer => 'snowball' }
      end
    end

    it 'creates mappings' do
      test_class.create_es_index
      test_class.create_es_mappings

      test_class.should have_new_mapping_for(:text_field,         :type => 'string', :index    => 'not_analyzed', :omit_norms => true, :index_options => 'docs')
      test_class.should have_new_mapping_for(:integer_field,      :type => 'integer')
      test_class.should have_new_mapping_for(:indexed_text_field, :type => 'string', :analyzer => 'snowball')
    end
  end

  context 'mapping is existing' do
    it "fails if there is a mapping conflict" do
      begin
        test_class.class_eval do
          mapping_for :text_field, { :type => 'string',  :index => 'not_analyzed' }
          mapping_for :text_field, { :type => 'integer', :index => 'not_analyzed' }
          create_es_index
          create_es_mappings
        end
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
        e.message.should =~ /MergeMappingException/
      end
    end

    it "does nothing if the mapping creation does not conflict" do
      expect do
        test_class.class_eval do
          mapping_for :text_field, { :type => 'string', :index => 'not_analyzed' }
          mapping_for :text_field, { :type => 'string', :index => 'not_analyzed' }
          create_es_index
          create_es_mappings
        end
      end.to_not raise_error
    end
  end
end
