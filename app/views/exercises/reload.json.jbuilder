json.set! :files do
  json.array! @exercise.files.visible, :content, :id
end
