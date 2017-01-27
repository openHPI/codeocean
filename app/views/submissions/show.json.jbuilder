json.extract! @submission, :id, :files
json.download_url download_submission_path(@submission)
json.score_url score_submission_path(@submission)
json.stop_url stop_submission_path(@submission)
json.download_file_url download_file_submission_path(@submission, 'a.').gsub(/a\.$/, '{filename}')
json.render_url render_submission_path(@submission, 'a.').gsub(/a\.$/, '{filename}')
json.run_url run_submission_path(@submission, 'a.').gsub(/a\.$/, '{filename}')
json.test_url test_submission_path(@submission, 'a.').gsub(/a\.$/, '{filename}')
