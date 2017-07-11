class ErrorTemplate < ActiveRecord::Base
  belongs_to :execution_environment
  has_and_belongs_to_many :error_template_attributes
end
