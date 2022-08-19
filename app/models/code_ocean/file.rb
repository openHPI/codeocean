# frozen_string_literal: true

require File.expand_path('../../uploaders/file_uploader', __dir__)
require File.expand_path('../../../lib/active_model/validations/boolean_presence_validator', __dir__)

module CodeOcean
  class File < ApplicationRecord
    include DefaultValues

    DEFAULT_WEIGHT = 1.0
    ROLES = %w[regular_file main_file reference_implementation executable_file teacher_defined_test user_defined_file
               user_defined_test teacher_defined_linter].freeze
    TEACHER_DEFINED_ROLES = ROLES - %w[user_defined_file]

    after_initialize :set_default_values
    before_validation :clear_weight, unless: :teacher_defined_assessment?
    before_validation :hash_content, if: :content_present?
    before_validation :set_ancestor_values, if: :incomplete_descendent?

    belongs_to :context, polymorphic: true
    belongs_to :file, class_name: 'CodeOcean::File', optional: true # This is only required for submissions and is validated below
    alias ancestor file
    belongs_to :file_type

    has_many :files, class_name: 'CodeOcean::File'
    has_many :testruns
    has_many :comments
    alias descendants files

    mount_uploader :native_file, FileUploader

    scope :editable, -> { where(read_only: false) }
    scope :visible, -> { where(hidden: false) }

    ROLES.each do |role|
      scope :"#{role}s", -> { where(role: role) }
    end
    scope :teacher_defined_assessments, -> { where(role: %w[teacher_defined_test teacher_defined_linter]) }

    default_scope { order(name: :asc) }

    validates :feedback_message, if: :teacher_defined_assessment?, presence: true
    validates :feedback_message, absence: true, unless: :teacher_defined_assessment?
    validates :hashed_content, if: :content_present?, presence: true
    validates :hidden, boolean_presence: true
    validates :name, presence: true
    validates :read_only, boolean_presence: true
    validates :role, inclusion: {in: ROLES}
    validates :weight, if: :teacher_defined_assessment?, numericality: true, presence: true
    validates :weight, absence: true, unless: :teacher_defined_assessment?
    validates :file, presence: true if :context.is_a?(Submission)

    validates_with FileNameValidator, fields: %i[name path file_type_id]

    ROLES.each do |role|
      define_method("#{role}?") { self.role == role }
    end

    def read
      if native_file?
        valid = Pathname(native_file.current_path).fnmatch? ::File.join(native_file.root, '**')
        return nil unless valid

        native_file.read
      else
        content
      end
    end

    def ancestor_id
      file_id || id
    end

    def clear_weight
      self.weight = nil
    end
    private :clear_weight

    def teacher_defined_assessment?
      teacher_defined_test? || teacher_defined_linter?
    end

    def content_present?
      content? || native_file?
    end
    private :content_present?

    def filepath
      if path.present?
        ::File.join(path, name_with_extension)
      else
        name_with_extension
      end
    end

    def hash_content
      self.hashed_content = Digest::MD5.new.hexdigest(read || '')
    end
    private :hash_content

    def incomplete_descendent?
      file_id.present? && file_type_id.blank?
    end
    private :incomplete_descendent?

    def name_with_extension
      name.to_s + (file_type&.file_extension || '')
    end

    def set_ancestor_values
      %i[feedback_message file_type_id hidden name path read_only role weight].each do |attribute|
        send(:"#{attribute}=", ancestor.send(attribute))
      end
    end
    private :set_ancestor_values

    def set_default_values
      set_default_values_if_present(content: '', hidden: false, read_only: false)
      set_default_values_if_present(weight: DEFAULT_WEIGHT) if teacher_defined_assessment?
    end
    private :set_default_values

    def visible
      !hidden
    end
  end
end
