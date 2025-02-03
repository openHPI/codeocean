# frozen_string_literal: true

switch_locale do
  json.name application_name
  json.lang I18n.locale
  # Categories: https://github.com/w3c/manifest/wiki/Categories
  json.categories %w[education productivity]
  json.start_url root_url
  json.scope Rails.application.config.relative_url_root
  json.display 'standalone'
  json.orientation 'any'
  json.theme_color '#333333'
  json.background_color '#FFFFFF'

  json.icons do
    json.array!([
      {
        src: asset_url('icon.png', skip_pipeline: true),
        sizes: '512x512',
        type: 'image/png',
      },
      {
        src: asset_url('icon.svg', skip_pipeline: true),
        sizes: 'any',
        type: 'image/svg+xml',
      },
    ])
  end

  json.shortcuts do
    json.array!([
      {
        name: t('request_for_comments.index.all'),
        url: request_for_comments_url,
      },
      {
        name: t('request_for_comments.index.my_rfc_activity'),
        url: my_rfc_activity_url,
      },
      {
        name: t('request_for_comments.index.my_comment_requests'),
        url: my_request_for_comments_url,
      },
    ])
  end

  json.related_applications do
    json.array!([
      # No app for CodeOcean yet :(, but empty array required for installation prompt
    ])
  end
  json.prefer_related_applications true
end
