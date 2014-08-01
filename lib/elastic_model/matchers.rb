RSpec::Matchers.define :have_mapping_for do |field_name, hash|
  match do |model|
    @model = model
    @hash = hash
    @field_name = field_name.to_s
    @mapping = es_mapping_properties_for(@model)[@field_name]

    unless @mapping.blank?
      @mapping.symbolize_keys!.should == @hash.symbolize_keys!
    end
  end

  failure_message do
    "#{@field_name} got: #{@mapping}, expected: #{@hash}"
  end
end

def es_mapping_for(model)
  $es.indices.get_mapping :index => model.es_index_name
end

def es_mapping_properties_for(model)
  es_mapping_for(model)[model.es_index_name]['mappings'][model.es_type]['properties']
end
