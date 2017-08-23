json.array!(@comments) do |comment|
  json.extract! comment, :id, :user_id, :file_id, :row, :column, :text, :username, :date, :updated
  json.url comment_url(comment, format: :json)
end
