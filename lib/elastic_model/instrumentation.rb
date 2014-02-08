module ElasticModel::Instrumentation
  extend ActiveSupport::Concern

  included do
    class_variable_set('@@es_index_name_var',    nil)
    class_variable_set('@@es_index_options_var', {} )
    class_variable_set('@@es_type_var',          nil)
    class_variable_set('@@es_mappings_var',      {} )

    def self.es_index_name(value=nil)
      if value
        class_variable_set('@@es_index_name_var', value)
      else
        if class_variable_get('@@es_index_name_var')
          "#{Rails.env}_#{class_variable_get('@@es_index_name_var')}"
        else
          "#{Rails.env}_#{base_class_name.pluralize}"
        end
      end
    end

    def self.es_index_options(value=nil)
      if value
        class_variable_set('@@es_index_options_var', value)
      else
        class_variable_get('@@es_index_options_var')
      end
    end

    def self.es_type(value=nil)
      if value
        class_variable_set('@@es_type_var', value)
      else
        class_variable_get('@@es_type_var') ? class_variable_get('@@es_type_var') : base_class_name
      end
    end

    def self.base_class_name
      self.name.split('::').last.underscore
    end

    def self.create_es_index
      unless $es.indices.exists :index => es_index_name
        $es.indices.create :index => es_index_name, :body => es_index_options
      end
    end

    def self.create_es_mappings
      class_variable_get('@@es_mappings_var').each do |field_name, options|
        $es.indices.put_mapping :index => es_index_name, :type => es_type, :body => {
          es_type.to_sym => { :properties => { field_name.to_sym => options } }
        }
      end
    end

    def self.mapping_for(field_name, options = {})
      class_variable_get('@@es_mappings_var')[field_name] = options
    end

    def save_to_es!
      $es.index :index => self.class.es_index_name, :type => self.class.es_type, :id => self.id, :body => self.as_json
    end
  end
end
