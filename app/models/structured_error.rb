class StructuredError < ActiveRecord::Base
  belongs_to :error_template
  belongs_to :submission
  belongs_to :file, class_name: 'CodeOcean::File'

  has_many :structured_error_attributes

  def self.create_from_template(template, message_buffer, submission)
    instance = self.create(error_template: template, submission: submission)
    template.error_template_attributes.each do | attribute |
      StructuredErrorAttribute.create_from_template(attribute, instance, message_buffer)
    end
    instance
  end

  def hint
    content = error_template.hint
    structured_error_attributes.each do | attribute |
      content.sub! "{{#{attribute.error_template_attribute.key}}}", attribute.value if attribute.match
    end
    content
  end
end
