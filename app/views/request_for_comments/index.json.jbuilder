# frozen_string_literal: true

json.array!(@request_for_comments) do |request_for_comment|
  json.extract! request_for_comment, :id, :user_id, :exercise_id, :file_id, :user_type
  json.url request_for_comment_url(request_for_comment, format: :json)
end
