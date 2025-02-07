# frozen_string_literal: true

JsRoutes.setup do |c|
  # Setup your JS module system:
  # ESM, CJS, AMD, UMD or nil.
  c.module_type = 'ESM'

  # Follow javascript naming convention
  # but lose the ability to match helper name
  # on backend and frontend consistently.
  # c.camel_case = true

  # Generate only helpers that match specific pattern.
  # c.exclude = /^api_/
  # c.include = /^admin_/

  # Generate `*_url` helpers besides `*_path`
  # for apps that work on multiple domains.
  c.url_links = true

  # Specify the file that will be generated.
  c.file = Rails.root.join('app/javascript/generated/routes.js')

  # Include JSDoc comments in generated file.
  c.documentation = true

  # More options:
  # @see https://github.com/railsware/js-routes#available-options
end
