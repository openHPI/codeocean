class StructuredError < ActiveRecord::Base
  belongs_to :error_template
  belongs_to :file, class_name: 'CodeOcean::File'

  def self.create_from_template(template, message_buffer)
    instance = self.create(error_template: template)
    template.error_template_attributes.each do |attribute|
      StructuredErrorAttribute.create_from_template(attribute, instance, message_buffer)
    end
    instance
  end
end
