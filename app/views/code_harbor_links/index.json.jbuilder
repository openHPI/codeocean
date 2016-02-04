json.array!(@code_harbor_links) do |code_harbor_link|
  json.extract! code_harbor_link, :id, :oauth2token
  json.url code_harbor_link_url(code_harbor_link, format: :json)
end
