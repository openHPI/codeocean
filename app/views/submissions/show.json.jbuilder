# frozen_string_literal: true

json.extract! @submission, :id, :files
json.download_url download_submission_path(@submission, format: :json)
json.score_url score_submission_path(@submission, format: :json)
json.download_file_url download_file_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/,
  '{filename}.json')
unless @embed_options[:disable_download]
  json.render_url @submission.collect_files.select(&:visible) do |files|
    host = ApplicationController::RENDER_HOST || request.host
    url = render_submission_url(@submission, files.filepath, host:)

    json.filepath files.filepath
    json.url AuthenticatedUrlHelper.sign(url, @submission)
  end
end
json.run_url run_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
json.test_url test_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
