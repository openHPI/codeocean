json.array!(@error_templates) do |error_template|
  json.extract! error_template, :id
  json.url error_template_url(error_template, format: :json)
end
