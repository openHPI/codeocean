# frozen_string_literal: true

json.array!(@comments) do |comment|
  json.extract! comment, :id, :user_id, :file_id, :row, :column, :text, :username, :date, :updated, :editable
  json.url comment_url(comment, format: :json)
end
