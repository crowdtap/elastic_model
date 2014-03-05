module ElasticModel::Instrumentation
  extend ActiveSupport::Concern

  included do
    class_variable_set('@@es_index_name_var',      nil  )
    class_variable_set('@@es_index_options_var',   {}   )
    class_variable_set('@@es_type_var',            nil  )
    class_variable_set('@@es_mappings_var',        {}   )
    class_variable_set('@@es_mapping_options_var', {}   )
    class_variable_set('@@es_parent_type_present', false)

    def self.base_class_name
      self.name.split('::').last.underscore
    end

    def self.default_es_index_name
      "#{Rails.env}_#{base_class_name.pluralize}"
    end

    def self.es_index_name(value=nil)
      if value
        class_variable_set('@@es_index_name_var', value)
      else
        if class_variable_get('@@es_index_name_var')
          "#{Rails.env}_#{class_variable_get('@@es_index_name_var')}"
        else
          self.default_es_index_name
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

    def self.es_mapping_options(options=nil)
      if options
        class_variable_set('@@es_mapping_options_var', options)
        class_variable_set('@@es_parent_type_present', true) unless options[:_parent].nil?
      else
        class_variable_get('@@es_mapping_options_var')
      end
    end

    def self.create_es_index
      unless $es.indices.exists :index => es_index_name
        $es.indices.create :index => es_index_name, :body => es_index_options
      end
    end

    def self.create_es_mappings
      params =  {
        :index => es_index_name,
        :type  => es_type,
        :body  => { es_type.to_sym => {} }
      }

      unless es_mapping_options.empty?
        params[:body][es_type.to_sym] = es_mapping_options
        $es.indices.put_mapping params
      end

      class_variable_get('@@es_mappings_var').each do |field_name, options|
        params[:body][es_type.to_sym].merge!({ :properties => { field_name.to_sym => options } })

        $es.indices.put_mapping params
      end
    end

    def self.mapping_for(field_name, options = {})
      class_variable_get('@@es_mappings_var')[field_name] = options
    end

    def save_to_es
      save_to_es! if self.changed?
    end

    def save_to_es!
      body   = self.as_json
      params = {
        :index => self.class.es_index_name,
        :type  => self.class.es_type,
        :id    => self.id,
        :body  => body
      }
      if self.class.has_es_parent?
        begin
          params[:parent] = self.es_parent_id
        rescue NoMethodError
          raise("You must define a #es_parent_id method to use _parent mapping")
        end
      end
      $es.index params
    end

    def delete_from_es
      $es.delete :index => self.class.es_index_name, :type => self.class.es_type, :id => self.id
    end

    private

    def self.has_es_parent?
      class_variable_get('@@es_parent_type_present')
    end
  end
end
