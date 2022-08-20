# frozen_string_literal: true

module CodeOcean
  class FileNameValidator < ActiveModel::Validator
    def validate(record)
      existing_files = File.where(name: record.name, path: record.path, file_type_id: record.file_type_id,
        context_id: record.context_id, context_type: record.context_type).to_a
      if !existing_files.empty? && (!record.context.is_a?(Exercise) || record.context.new_record?)
        record.errors.add(:base, 'Duplicate')
      end
    end
  end
end
