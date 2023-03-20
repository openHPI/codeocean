# frozen_string_literal: true

class StructuredError < ApplicationRecord
  belongs_to :error_template
  belongs_to :submission

  has_many :structured_error_attributes, dependent: :destroy

  def self.create_from_template(template, message_buffer, submission)
    create(
      error_template: template,
      submission:,
      structured_error_attributes: template.error_template_attributes.filter_map do |attribute|
        StructuredErrorAttribute.create_from_template(attribute, message_buffer)
      end
    )
  end

  def hint
    content = error_template.hint
    structured_error_attributes.each do |attribute|
      content.sub! "{{#{attribute.error_template_attribute.key}}}", attribute.value if attribute.match
    end
    content
  end
end
