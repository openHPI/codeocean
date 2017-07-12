class StructuredErrorAttribute < ActiveRecord::Base
  belongs_to :structured_error
  belongs_to :error_template_attribute

  def self.create_from_template(attribute, structured_error, message_buffer)
    value = message_buffer.match(attribute.regex).captures[0]
    self.create(structured_error: structured_error, error_template_attribute: attribute, value: value)
  end
end
