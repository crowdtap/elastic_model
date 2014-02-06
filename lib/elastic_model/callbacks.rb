module ElasticModel::Callbacks
  extend ActiveSupport::Concern

  included do
    after_save    :save_to_es
    after_destroy :delete_from_es

    def save_to_es
      if self.changed?
        $es.index :index => self.class.es_index_name, :type => self.class.es_type, :id => self.id, :body => self.as_json
      end
    end

    def delete_from_es
      $es.delete :index => self.class.es_index_name, :type => self.class.es_type, :id => self.id
    end
  end
end
