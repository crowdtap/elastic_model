require 'spec_helper'

describe ElasticModel::Instrumentation do
  let(:test_class_1) do
    define_constant('test_class_1') do
      include ElasticModel::Instrumentation
    end
  end

  let(:test_class_2) do
    define_constant('test_class_2') do
      include ElasticModel::Instrumentation
    end
  end

  describe '.es_index_name' do
    subject { test_class_1 }

    before { test_class_1.stubs(:name => "V2::Engagement::TestClass") }

    it "returns the class name prefixed with the Rails environment by default" do
      Rails.stubs(:env => 'foo')
      subject.es_index_name nil
      subject.es_index_name.should == 'foo_test_classes'
    end

    it "returns the set index name prefixed with the Rails environment when index name is defined" do
      subject.es_index_name 'voila'
      Rails.stubs(:env => 'foo')
      subject.es_index_name.should == 'foo_voila'
    end

    it "ensures two classes are not sharing indices" do
      subject.es_index_name 'voila'
      test_class_2.es_index_name 'whatever'
      subject.es_index_name.should_not == test_class_2.es_index_name
    end
  end

  describe '.es_index_options' do
    subject { test_class_1 }

    it "returns a empty hash when not set" do
      subject.es_index_options.should == {}
    end

    it "allows assignment and returns the assigned variable" do
      settings_hash = { :settings => 'the settings' }
      subject.es_index_options settings_hash
      subject.es_index_options.should == settings_hash
    end
  end

  describe '.es_type' do
    subject { test_class_1 }

    before { test_class_1.stubs(:name => "V2::Engagement::TestClass") }

    it "returns the underscored class name by default" do
      subject.es_type.should == 'test_class'
    end

    it "returns the set es type when type is defined" do
      subject.es_type 'voila'
      subject.es_type.should == 'voila'
    end
  end

  describe '.create_es_index' do
    subject { test_class_1 }

    it 'creates a new index if it does not already exist' do
      $es.stubs(:indices => stub(:exists => false, :create => true))
      subject.create_es_index
      $es.indices.should have_received(:create).once
    end

    it 'does not create a new index if it does exist' do
      $es.stubs(:indices => stub(:exists => true))
      subject.create_es_index
      $es.indices.should have_received(:create).never
    end
  end
end
