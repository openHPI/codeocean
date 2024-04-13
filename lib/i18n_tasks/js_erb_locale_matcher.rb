# frozen_string_literal: true

require 'i18n/tasks/scanners/file_scanner'

module I18nTasks
  class JsErbLocaleMatcher < I18n::Tasks::Scanners::FileScanner
    include I18n::Tasks::Scanners::RelativeKeys
    include I18n::Tasks::Scanners::OccurrenceFromPosition

    # @return [Array<[absolute key, Results::Occurrence]>]
    def scan_file(path)
      text = read_file(path)
      text.scan(/I18n.t\(['"]([\.\w]*)["'].*\)/).map do |match|
        occurrence = occurrence_from_position(
          path, text, Regexp.last_match.offset(0).first
        )
        [match.first, occurrence]
      end
    end
  end
end

I18n::Tasks.add_scanner 'I18nTasks::JsErbLocaleMatcher', only: %w[*.js.erb]
