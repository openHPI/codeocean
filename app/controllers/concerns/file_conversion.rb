# frozen_string_literal: true

module FileConversion
  private

  def convert_files_json_to_files(files_json)
    # Return an empty list of files and directories if the files_json is nil
    return [[], []] if files_json.blank?

    all_file_types = FileType.all
    directories = []
    files = files_json['files'].filter_map do |file|
      # entryType: `-` describes a regular file, `d` a directory. See `info ls` for others
      directories.push(file['name']) if file['entryType'] == 'd'
      next unless file['entryType'] == '-'

      extension = File.extname(file['name'])
      name = File.basename(file['name'], extension)
      path = File.dirname(file['name']).sub(%r{^(?>\./|\.)}, '').presence
      file_type = all_file_types.detect {|ft| ft.file_extension == extension } || FileType.new(file_extension: extension)
      CodeOcean::File.new(
        name:,
        path:,
        size: file['size'],
        owner: file['owner'],
        group: file['group'],
        permissions: file['permissions'],
        updated_at: file['modificationTime'],
        file_type:
      )
    end
    [augment_files_for_download(files), directories]
  end

  def augment_files_for_download(files)
    raise NotImplementedError
  end
end
