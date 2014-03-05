require 'spec_helper'

describe ElasticModel::Callbacks do
  describe "saving indexes with associations" do
    let!(:parent_class) do
      define_constant('parent_association') do
        include Mongoid::Document
        include ElasticModel::Instrumentation
        es_index_name "test_classes"
        es_type "parent_test_type"

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

        create_es_index
        create_es_mappings

        def es_parent_id
          parent_association_id
        end
      end
    end

    context "when a parent es_type is not defined for the index" do
      it "doesn't pass anything  in to set the parent_association_id property" do
        test_instance = valid_child_class.create(:count => 1, :parent_association => parent_instance)
        res = $es.get :index => valid_associated_class.es_index_name,
                      :type  => valid_associated_class.es_type,
                      :id    => test_instance.id

        res['_source']['parent_association_id'].should be_nil
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
          es_index_name "test_classes"
          es_mapping_options({
            :_parent => { :type => "parent_test_type" }
          })

          create_es_index
          create_es_mappings
        end
      end

      it "raises an exception if the parent_id method is not implemented" do
        test_instance = invalid_child_class.new(:count => 1, :parent_association => parent_instance)
        expect do
          test_instance.save!
        end.to raise_error("You must define a #parent_id method to use _parent mapping")
      end

      it "passes the #es_parent_id in as the parent and routing param to set the parent_association_id property" do
        test_instance = valid_child_class.new(:count => 1, :parent_association => parent_instance)
        expect do
          test_instance.save!
        end.to_not raise_error

        res = $es.get :index => valid_child_class.es_index_name,
                      :type  => valid_child_class.es_type,
                      :id    => test_instance.id
        res['_source']['parent_association_id'].should == parent_insance.id.to_s
      end
    end
  end
end