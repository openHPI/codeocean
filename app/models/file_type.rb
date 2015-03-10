class FileType < ActiveRecord::Base
  include Creation

  AUDIO_FILE_EXTENSIONS = %w(.aac .flac .m4a .mp3 .ogg .wav .wma)
  IMAGE_FILE_EXTENSIONS = %w(.bmp .gif .jpeg .jpg .png)
  VIDEO_FILE_EXTENSIONS = %w(.avi .flv .mkv .mp4 .m4v .ogv .webm)

  after_initialize :set_default_values

  has_many :execution_environments
  has_many :files

  validates :binary, inclusion: {in: [true, false]}
  validates :editor_mode, presence: true, unless: :binary?
  validates :executable, inclusion: {in: [true, false]}
  validates :indent_size, presence: true, unless: :binary?
  validates :name, presence: true
  validates :renderable, inclusion: {in: [true, false]}

  [:audio, :image, :video].each do |type|
    define_method("#{type}?") do
      self.class.const_get("#{type.upcase}_FILE_EXTENSIONS").include?(file_extension)
    end
  end

  def set_default_values
    self.binary ||= false
    self.executable ||= false
    self.renderable ||= false
  end
  private :set_default_values

  def to_s
    name
  end
end
