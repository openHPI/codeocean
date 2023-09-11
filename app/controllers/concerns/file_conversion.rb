# frozen_string_literal: true

module FileConversion
  private

  def convert_files_json_to_files(files_json)
    retry_block do
      # Return an empty list of files and directories if the files_json is nil
      return [[], []] if files_json.blank?

      directories = []
      files = files_json['files'].filter_map do |file|
        # entryType: `-` describes a regular file, `d` a directory. See `info ls` for others
        directories.push(file['name']) if file['entryType'] == 'd'
        next unless file['entryType'] == '-'

        file['extension'] = File.extname(file['name'])
        file
      end

      # Optimize SQL queries: We are first fetching all required file types from the database.
      # Then, we store them in a hash, so that we can access them by using their file extension.
      file_types = {}
      FileType.where(file_extension: files.pluck('extension')).find_each do |file_type|
        file_types[file_type.file_extension] = file_type
      end

      files.map! do |file|
        CodeOcean::File.new(
          name: File.basename(file['name'], file['extension']),
          path: File.dirname(file['name']).sub(%r{^(?>\./|\.)}, '').presence,
          size: file['size'],
          owner: file['owner'],
          group: file['group'],
          permissions: file['permissions'],
          updated_at: file['modificationTime'],
          file_type: file_types[file['extension']] || FileType.new(file_extension: file['extension'])
        )
      end
      [augment_files_for_download(files), directories]
    end
  end

  def augment_files_for_download(files)
    raise NotImplementedError
  end

  def retry_block(count: 1)
    yield
  rescue ActiveRecord::StatementInvalid => e
    count -= 1
    retry if count.positive?

    raise e
  end
end
