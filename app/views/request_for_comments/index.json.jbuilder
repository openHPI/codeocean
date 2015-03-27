json.array!(@request_for_comments) do |request_for_comment|
  json.extract! request_for_comment, :id, :requestorid, :exerciseid, :fileid, :requested_at
  json.url request_for_comment_url(request_for_comment, format: :json)
end
