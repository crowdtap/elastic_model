require 'spec_helper'

describe ElasticModel::Callbacks do
  describe "saving indexes with associations" do
    let!(:parent_class) do
      define_constant('parent_association') do
        include Mongoid::Document
        include ElasticModel::Instrumentation
        include ElasticModel::Callbacks
        es_index_name "test_classes"
        es_type "parent_test_type"

        mapping_for :_id, { :type => 'string', :index => 'not_analyzed' }

        create_es_index
        create_es_mappings
      end
    end
    let!(:parent_instance) { parent_class.create }

    let!(:valid_associated_class) do
      define_constant('valid_associated_class') do
        include Mongoid::Document
        include ElasticModel::Instrumentation
        include ElasticModel::Callbacks
        create_es_index

        field :count, :type => Integer
        belongs_to :parent_association
        es_index_name "test_classes"

        mapping_for :_id, { :type => 'string', :index => 'not_analyzed' }
        mapping_for :parent_association_id, { :type => 'string', :index => 'not_analyzed' }
        mapping_for :count, { :type => 'integer' }

        create_es_index
        create_es_mappings
      end
    end

    context "when a parent es_type is not defined for the index" do
      it "doesn't raise when saving to the index" do
        expect do
          valid_associated_class.create(:count => 1, :parent_association => parent_instance)
        end.to_not raise_error
      end
    end

    context "when a parent es_type is defined for the index" do
      let!(:valid_child_class) do
        define_constant('valid_child_class') do
          include Mongoid::Document
          include ElasticModel::Instrumentation
          include ElasticModel::Callbacks
          create_es_index

          field :count, :type => Integer
          belongs_to :parent_association
          es_index_name "test_classes"
          es_mapping_options({
            :_parent  => { :type => "parent_test_type" },
            :_routing => { :path => "parent_association_id" }
          })

          mapping_for :_id, { :type => 'string', :index => 'not_analyzed' }
          mapping_for :parent_association_id, { :type => 'string', :index => 'not_analyzed' }
          mapping_for :count, { :type => 'integer' }

          create_es_index
          create_es_mappings

          def es_parent_id
            parent_association_id
          end
        end
      end

      let!(:invalid_child_class) do
        define_constant('invalid_child_class') do
          include Mongoid::Document
          include ElasticModel::Instrumentation
          include ElasticModel::Callbacks
          belongs_to :parent_association

          field :count, :type => Integer
          es_index_name "test_classes"
          es_mapping_options({
            :_parent  => { :type => "parent_test_type" },
            :_routing => { :path => "parent_association_id", :required => false }
          })

          mapping_for :_id, { :type => 'string', :index => 'not_analyzed' }
          mapping_for :parent_association_id, { :type => 'string', :index => 'not_analyzed' }
          mapping_for :count, { :type => 'integer' }

          create_es_index
          create_es_mappings
        end
      end

      it "raises an exception if the #es_parent_id method is not implemented" do
        test_instance = invalid_child_class.new(:count => 1, :parent_association => parent_instance)
        expect do
          test_instance.save!
        end.to raise_error("You must define a #es_parent_id method to use _parent mapping")
      end

      it "passes the #es_parent_id in as the parent and routing params" do
        test_instance = valid_child_class.new(:count => 1, :parent_association => parent_instance)
        expect do
          test_instance.save!
        end.to_not raise_error

        res = $es.get :index   => valid_child_class.es_index_name,
                      :type    => valid_child_class.es_type,
                      :routing => test_instance.parent_association_id,
                      :id      => test_instance.id
        res['_source']['parent_association_id'].should == parent_instance.id.to_s
      end
    end
  end
end
