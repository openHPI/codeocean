require File.expand_path('../../../lib/active_model/validations/boolean_presence_validator', __FILE__)

class FileType < ActiveRecord::Base
  include Creation
  include DefaultValues

  AUDIO_FILE_EXTENSIONS = %w(.aac .flac .m4a .mp3 .ogg .wav .wma)
  IMAGE_FILE_EXTENSIONS = %w(.bmp .gif .jpeg .jpg .png)
  VIDEO_FILE_EXTENSIONS = %w(.avi .flv .mkv .mp4 .m4v .ogv .webm)

  after_initialize :set_default_values

  has_many :execution_environments
  has_many :files
  has_many :file_templates

  validates :binary, boolean_presence: true
  validates :editor_mode, presence: true, unless: :binary?
  validates :executable, boolean_presence: true
  validates :indent_size, presence: true, unless: :binary?
  validates :name, presence: true
  validates :renderable, boolean_presence: true

  [:audio, :image, :video].each do |type|
    define_method("#{type}?") do
      self.class.const_get("#{type.upcase}_FILE_EXTENSIONS").include?(file_extension)
    end
  end

  def set_default_values
    set_default_values_if_present(binary: false, executable: false, renderable: false)
  end
  private :set_default_values

  def to_s
    name
  end
end
