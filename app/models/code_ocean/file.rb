require File.expand_path('../../../uploaders/file_uploader', __FILE__)

module CodeOcean
  class File < ActiveRecord::Base
    include DefaultValues

    DEFAULT_WEIGHT = 1.0
    ROLES = %w(main_file reference_implementation regular_file teacher_defined_test user_defined_file user_defined_test)
    TEACHER_DEFINED_ROLES = ROLES - %w(user_defined_file)

    after_initialize :set_default_values
    before_validation :set_ancestor_values, if: :incomplete_descendent?
    before_validation :hash_content, if: :content_present?

    belongs_to :context, polymorphic: true
    belongs_to :execution_environment
    belongs_to :file
    alias_method :ancestor, :file
    belongs_to :file_type

    has_many :files
    alias_method :descendants, :files

    mount_uploader :native_file, FileUploader

    scope :editable, -> { where(read_only: false) }
    scope :visible, -> { where(hidden: false) }

    ROLES.each do |role|
      scope :"#{role}s", -> { where(role: role) }
    end

    validates :feedback_message, if: :teacher_defined_test?, presence: true
    validates :feedback_message, absence: true, unless: :teacher_defined_test?
    validates :file_type_id, presence: true
    validates :hashed_content, if: :content_present?, presence: true
    validates :hidden, inclusion: {in: [true, false]}
    validates :name, presence: true
    validates :read_only, inclusion: {in: [true, false]}
    validates :role, inclusion: {in: ROLES}
    validates :weight, if: :teacher_defined_test?, numericality: true, presence: true
    validates :weight, absence: true, unless: :teacher_defined_test?

    ROLES.each do |role|
      define_method("#{role}?") { self.role == role }
    end

    def ancestor_id
      file_id || id
    end

    def content_present?
      content? || native_file?
    end
    private :content_present?

    def hash_content
      self.hashed_content = Digest::MD5.new.hexdigest(file_type.binary? ? ::File.new(native_file.file.path, 'r').read : content)
    end
    private :hash_content

    def incomplete_descendent?
      file_id.present? && file_type_id.blank?
    end
    private :incomplete_descendent?

    def name_with_extension
      name + (file_type.file_extension || '')
    end

    def set_ancestor_values
      [:feedback_message, :file_type_id, :hidden, :name, :path, :read_only, :role, :weight].each do |attribute|
        send(:"#{attribute}=", ancestor.send(attribute))
      end
    end
    private :set_ancestor_values

    def set_default_values
      set_default_values_if_present(content: '', hidden: false, read_only: false)
      set_default_values_if_present(weight: DEFAULT_WEIGHT) if teacher_defined_test?
    end
    private :set_default_values

    def visible
      !hidden
    end
  end
end
