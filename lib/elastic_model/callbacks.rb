module ElasticModel::Callbacks
  extend ActiveSupport::Concern

  included do
    after_save    :save_to_es
    after_destroy :delete_from_es
  end
end
