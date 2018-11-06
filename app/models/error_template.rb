class ErrorTemplate < ApplicationRecord
  belongs_to :execution_environment
  has_and_belongs_to_many :error_template_attributes

  def to_s
    name
  end
end
