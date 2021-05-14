# frozen_string_literal: true

json.set! :files do
  json.array! @exercise.files.visible, :content, :id
end
