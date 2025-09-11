# frozen_string_literal: true

require 'i18n'
require 'i18n/tasks/scanners/file_scanner'

module I18nTasks
  class SlimRowLocaleMatcher < I18n::Tasks::Scanners::FileScanner
    include I18n::Tasks::Scanners::RelativeKeys
    include I18n::Tasks::Scanners::OccurrenceFromPosition

    AppI18n = I18n.dup
    Dir[File.join(File.expand_path('config/locales'), '**/*.yml')].each do |locale_file|
      AppI18n.config.load_path << locale_file
    end

    # @return [Array<[absolute key, Results::Occurrence]>]
    def scan_file(path)
      text = read_file(path)
      text.scan(/row\(.*label:\s*['"]([.\w]*)["'].*\)/).map do |match|
        occurrence = occurrence_from_position(
          path, text, Regexp.last_match.offset(0).first
        )
        # This lookup is based on `ApplicationHelper#label_column`
        label = AppI18n.exists?("activerecord.attributes.#{match.first}") ? "activerecord.attributes.#{match.first}" : match.first
        [absolute_key(label, path), occurrence]
      end
    end
  end
end

I18n::Tasks.add_scanner 'I18nTasks::SlimRowLocaleMatcher', only: %w[*.html.slim]
