json.array!(@request_for_comments) do |request_for_comment|
  json.extract! request_for_comment, :id, :requestor_user_id, :exercise_id, :file_id, :requested_at, :user_type
  json.url request_for_comment_url(request_for_comment, format: :json)
end
