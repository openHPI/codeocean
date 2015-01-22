class FileUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/files/#{model.id}"
  end
end
