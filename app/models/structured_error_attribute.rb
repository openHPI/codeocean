class StructuredErrorAttribute < ActiveRecord::Base
  belongs_to :structured_error
  belongs_to :error_template_attribute

  def self.create_from_template(attribute, structured_error, message_buffer)
    value = nil
    result = message_buffer.match(attribute.regex)
    if result != nil
      if result.captures.size > 0
        value = result.captures[0]
      end
    end
    self.create(structured_error: structured_error, error_template_attribute: attribute, value: value, match: result != nil)
  end
end
