require File.expand_path('../../../uploaders/file_uploader', __FILE__)
require File.expand_path('../../../../lib/active_model/validations/boolean_presence_validator', __FILE__)

module CodeOcean

  class FileNameValidator < ActiveModel::Validator
    def validate(record)
      existing_files = File.where(name: record.name, path: record.path, file_type_id: record.file_type_id,
                                  context_id: record.context_id, context_type: record.context_type).to_a
      unless existing_files.empty?
        if (not record.context.is_a?(Exercise)) || (record.context.new_record?)
          record.errors[:base] << 'Duplicate'
        end
      end
    end
  end

  class File < ActiveRecord::Base
    include DefaultValues

    DEFAULT_WEIGHT = 1.0
    ROLES = %w(main_file reference_implementation regular_file teacher_defined_test user_defined_file user_defined_test)
    TEACHER_DEFINED_ROLES = ROLES - %w(user_defined_file)

    after_initialize :set_default_values
    before_validation :clear_weight, unless: :teacher_defined_test?
    before_validation :hash_content, if: :content_present?
    before_validation :set_ancestor_values, if: :incomplete_descendent?

    belongs_to :context, polymorphic: true
    belongs_to :execution_environment
    belongs_to :file
    alias_method :ancestor, :file
    belongs_to :file_type

    has_many :files
    has_many :testruns
    has_many :comments
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
    validates :hidden, boolean_presence: true
    validates :name, presence: true
    validates :read_only, boolean_presence: true
    validates :role, inclusion: {in: ROLES}
    validates :weight, if: :teacher_defined_test?, numericality: true, presence: true
    validates :weight, absence: true, unless: :teacher_defined_test?

    validates_with FileNameValidator, fields: [:name, :path, :file_type_id]

    ROLES.each do |role|
      define_method("#{role}?") { self.role == role }
    end

    def full_file_name
      filename = ''
      filename += "#{self.path}/" unless self.path.blank?
      filename += "#{self.name}#{self.file_type.file_extension}"
      filename
    end

    def ancestor_id
      file_id || id
    end

    def clear_weight
      self.weight = nil
    end
    private :clear_weight

    def content_present?
      content? || native_file?
    end
    private :content_present?

    def hash_content
      self.hashed_content = Digest::MD5.new.hexdigest(file_type.try(:binary?) ? ::File.new(native_file.file.path, 'r').read : content)
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
