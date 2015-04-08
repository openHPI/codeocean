json.array!(@comments) do |comment|
  json.extract! comment, :id, :user_id, :file_id, :row, :column, :text
  json.url comment_url(comment, format: :json)
end
