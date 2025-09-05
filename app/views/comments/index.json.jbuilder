# frozen_string_literal: true

json.array!(@comments) do |comment|
  json.extract! comment, :id, :user_id, :file_id, :row, :column, :text
  json.username comment.user.displayname
  json.date comment.created_at.strftime('%d.%m.%Y %k:%M')
  json.updated (comment.created_at != comment.updated_at)
  json.editable policy(comment).edit?
  json.reportable policy(comment).report?
  json.url comment_url(comment, format: :json)
end
