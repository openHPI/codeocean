# frozen_string_literal: true

class StructuredErrorAttribute < ApplicationRecord
  belongs_to :structured_error
  belongs_to :error_template_attribute

  def self.create_from_template(attribute, structured_error, message_buffer)
    value = nil
    result = message_buffer.match(attribute.regex)
    if !result.nil? && result.captures.size.positive?
      value = result.captures[0]
    end
    create(structured_error:, error_template_attribute: attribute, value:,
      match: !result.nil?)
  end
end
