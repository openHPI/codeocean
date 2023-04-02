# frozen_string_literal: true

require File.expand_path('../../uploaders/file_uploader', __dir__)

module CodeOcean
  class File < ApplicationRecord
    include DefaultValues

    DEFAULT_WEIGHT = 1.0
    ROLES = %w[regular_file main_file reference_implementation executable_file teacher_defined_test user_defined_file
               user_defined_test teacher_defined_linter].freeze
    TEACHER_DEFINED_ROLES = ROLES - %w[user_defined_file]
    OWNER_READ_PERMISSION = 0o400
    OTHER_READ_PERMISSION = 0o004

    after_initialize :set_default_values
    before_validation :clear_weight, unless: :teacher_defined_assessment?
    before_validation :hash_content, if: :content_present?
    before_validation :set_ancestor_values, if: :incomplete_descendent?

    attr_writer :size
    # These attributes are mainly used when retrieving files from a runner
    attr_accessor :download_path, :owner, :group, :privileged_execution
    attr_reader :permissions

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
      scope :"#{role}s", -> { where(role:) }
    end
    scope :teacher_defined_assessments, -> { where(role: %w[teacher_defined_test teacher_defined_linter]) }

    default_scope { order(name: :asc) }

    validates :feedback_message, if: :teacher_defined_assessment?, presence: true
    validates :feedback_message, absence: true, unless: :teacher_defined_assessment?
    validates :hashed_content, if: :content_present?, presence: true
    validates :hidden, inclusion: [true, false]
    validates :name, presence: true
    validates :read_only, inclusion: [true, false]
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
        return nil unless native_file_location_valid?

        native_file.read
      else
        content
      end
    end

    def native_file_location_valid?
      real_location = Pathname(native_file.current_path).realpath
      upload_location = Pathname(::File.join(native_file.root, 'uploads')).realpath
      real_location.fnmatch? ::File.join(upload_location.to_s, '**')
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

    def filepath_without_extension
      if path.present?
        ::File.join(path, name)
      else
        name
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

    def name_with_extension_and_size
      "#{name_with_extension} (#{ActionController::Base.helpers.number_to_human_size(size)})"
    end

    def set_ancestor_values
      %i[feedback_message file_type hidden name path read_only role weight].each do |attribute|
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

    def size
      @size ||= if native_file?
                  native_file.size
                else
                  content.size
                end
    end

    def permissions=(permission_string)
      # We iterate through the permission string (e.g., `rwxrw-r--`) as received through Linux
      # For each character in the string, we check for a corresponding permission (which is available if the character is not `-`)
      # Then, we use a bit shift to move a `1` to the position of the given permission.
      # First, it is moved within a group (e.g., `r` in `rwx` is moved twice to the left, `w` once, `x` not at all)
      # Second, the bit is moved in accordance with the group (e.g., the `owner` is moved twice, the `group` once, the `other` group not at all)
      # Finally, a sum is created, which technically could be an OR operation as well.
      @permissions = permission_string.chars.map.with_index do |permission, index|
        next 0 if permission == '-' # No permission

        bit = 0b1 << ((2 - index) % 3) # Align bit in respective group
        bit << ((2 - (index / 3)) * 3) # Align bit in bytes (for the group)
      end.sum
    end

    def missing_read_permissions?
      return false if permissions.blank?

      # We use a bitwise AND with the permission bits and compare that to zero
      if privileged_execution.present?
        (permissions & OWNER_READ_PERMISSION).zero?
      else
        (permissions & OTHER_READ_PERMISSION).zero?
      end
    end
  end
end
