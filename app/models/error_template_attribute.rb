class ErrorTemplateAttribute < ActiveRecord::Base
  has_and_belongs_to_many :error_template

  def to_s
    "#{id} [#{key}]"
  end
end
