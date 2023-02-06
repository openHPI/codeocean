# frozen_string_literal: true

class MigrateFiletypeExtensionsNotNil < ActiveRecord::Migration[7.0]
  def change
    FileType.all.find_all {|file_type| file_type.file_extension.nil? }.each do |file_type|
      file_type.update file_extension: ''
    end
  end
end
