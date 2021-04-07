json.extract! @submission, :id, :files
json.download_url download_submission_path(@submission, format: :json)
json.score_url score_submission_path(@submission, format: :json)
json.download_file_url download_file_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
json.render_url render_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
json.run_url run_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
json.test_url test_submission_path(@submission, 'a.', format: :json).gsub(/a\.\.json$/, '{filename}.json')
