# frozen_string_literal: true

json.id @submission.id
json.files @submission.files do |file|
  json.extract! file, :id, :file_id
end
unless @embed_options[:disable_download]
  json.render_url @submission.collect_files.select(&:visible) do |files|
    host = ApplicationController::RENDER_HOST || request.host
    url = render_submission_url(@submission, files.filepath, host:)

    json.filepath files.filepath
    json.url AuthenticatedUrlHelper.sign(url, @submission)
  end
end
