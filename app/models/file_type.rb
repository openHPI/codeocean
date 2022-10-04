# frozen_string_literal: true

require File.expand_path('../../lib/active_model/validations/boolean_presence_validator', __dir__)

class FileType < ApplicationRecord
  include Creation
  include DefaultValues

  AUDIO_FILE_EXTENSIONS = %w[.aac .flac .m4a .mp3 .ogg .wav .wma].freeze
  COMPRESSED_FILE_EXTENSIONS = %w[.7z .bz2 .gz .rar .tar .zip].freeze
  CSV_FILE_EXTENSIONS = %w[.csv].freeze
  EXCEL_FILE_EXTENSIONS = %w[.xls .xlsx].freeze
  IMAGE_FILE_EXTENSIONS = %w[.bmp .gif .jpeg .jpg .png].freeze
  PDF_FILE_EXTENSIONS = %w[.pdf].freeze
  POWERPOINT_FILE_EXTENSIONS = %w[.ppt .pptx].freeze
  VIDEO_FILE_EXTENSIONS = %w[.avi .flv .mkv .mp4 .m4v .ogv .webm].freeze
  WORD_FILE_EXTENSIONS = %w[.doc .docx].freeze

  after_initialize :set_default_values

  has_many :execution_environments
  has_many :files, class_name: 'CodeOcean::File'
  has_many :file_templates

  validates :binary, boolean_presence: true
  validates :editor_mode, presence: true, unless: :binary?
  validates :executable, boolean_presence: true
  validates :indent_size, presence: true, unless: :binary?
  validates :name, presence: true
  validates :renderable, boolean_presence: true

  %i[audio compressed csv excel image pdf powerpoint video word].each do |type|
    define_method("#{type}?") do
      self.class.const_get("#{type.upcase}_FILE_EXTENSIONS").include?(file_extension)
    end
  end

  def set_default_values
    set_default_values_if_present(binary: false, executable: false, renderable: false)
  end
  private :set_default_values

  def programming_language
    editor_mode&.gsub('ace/mode/', '')
  end

  def to_s
    name
  end
end
