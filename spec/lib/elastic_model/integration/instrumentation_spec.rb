require 'spec_helper'

describe ElasticModel::Instrumentation do
  around :each do |test|
    if $es.indices.exists index: 'development_test_classes'
      $es.indices.delete index: 'development_test_classes'
    end
    test.run
    if $es.indices.exists index: 'development_test_classes'
      $es.indices.delete index: 'development_test_classes'
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
      settings[test_class.es_index_name]["settings"]["index"]["number_of_replicas"].to_i.should == 0
      settings[test_class.es_index_name]["settings"]["index"]["number_of_shards"].to_i.should == 1
    end

    it 'does not raise error when index is already existing' do
      test_class.create_es_index
      expect { test_class.create_es_index }.not_to raise_error
    end
  end

  describe '.mapping_for & .create_es_mappings' do
    context 'when mapping is not existing' do
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

        test_class.should have_mapping_for(:text_field,         :type => 'string', :index    => 'not_analyzed')
        test_class.should have_mapping_for(:integer_field,      :type => 'integer')
        test_class.should have_mapping_for(:indexed_text_field, :type => 'string', :analyzer => 'snowball')
      end
    end

    context 'when mapping is existing' do
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

  describe '.es_mapping_options' do
    before do
      define_constant('parent_class') do
        include Mongoid::Document
        include ElasticModel::Instrumentation
        es_index_name "test_classes"
        es_type "parent_test_type"

        create_es_index
        create_es_mappings
      end

      test_class.class_eval do
        belongs_to :parent_class
        es_mapping_options({
          :_parent => { :type => "parent_test_type" }
        })
        es_index_name "test_classes"
      end

      test_class.create_es_index
      test_class.create_es_mappings
    end

    it "creates a mapping with the mapping options set" do
      test_index = $es.indices.get_mapping :index => test_class.es_index_name
      test_index[test_class.es_index_name]['mappings'][test_class.es_type].should_not be_nil
      child_index = test_index[test_class.es_index_name]['mappings'][test_class.es_type]
      child_index["_parent"].should == { "type" => "parent_test_type" }
    end
  end

  describe '.save_to_es!' do
    it "saves to Elasticsearch always" do
      test_class.class_eval do
        create_es_index
        create_es_mappings
      end
      instance = test_class.new

      instance.save_to_es!
      results = $es.get :index => test_class.es_index_name, :id => instance.id
      results["_version"].to_i.should == 1
      instance.save_to_es!
      results = $es.get :index => test_class.es_index_name, :id => instance.id
      results["_version"].to_i.should == 2
    end
  end
end
