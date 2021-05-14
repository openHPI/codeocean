# frozen_string_literal: true

json.extract! @request_for_comment, :id, :user_id, :exercise_id, :file_id, :created_at, :updated_at, :user_type, :solved
