class StructuredError < ActiveRecord::Base
  belongs_to :error_template
  belongs_to :file, class_name: 'CodeOcean::File'
end
