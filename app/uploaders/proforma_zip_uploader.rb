# frozen_string_literal: true

class ProformaZipUploader < CarrierWave::Uploader::Base
  def filename
    SecureRandom.uuid
  end
end
