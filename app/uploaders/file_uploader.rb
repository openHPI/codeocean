# frozen_string_literal: true

class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/files/#{model.id}"
  end

  def url(*args)
    if model.path?
      desired = encode_path("uploads/files/#{model.id}/#{model.path}")
      generated = encode_path(store_dir)
      super&.sub(generated, desired)
    else
      super
    end
  end
end
