class StructuredErrorAttribute < ActiveRecord::Base
  belongs_to :structured_error
  belongs_to :error_template_attribute
end
