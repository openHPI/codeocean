# frozen_string_literal: true

module CodeOcean
  class FileNameValidator < ActiveModel::Validator
    def validate(record)
      existing_files = File.where(name: record.name, path: record.path, file_type: record.file_type,
        context: record.context)
      if !existing_files.empty? && (!record.context.is_a?(Exercise) || record.context.new_record?)
        record.errors.add(:base, 'Duplicate')
      end
    end
  end
end
