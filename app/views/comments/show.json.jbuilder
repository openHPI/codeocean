# frozen_string_literal: true

json.extract! @comment, :id, :user_id, :file_id, :row, :column, :text, :created_at, :updated_at
