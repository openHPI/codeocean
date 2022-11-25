# frozen_string_literal: true

class LinterCheckRun < ApplicationRecord
  belongs_to :linter_check
  belongs_to :testrun
  belongs_to :file, class_name: 'CodeOcean::File'

  def self.create_from(testrun, assessment)
    assessment[:detailed_linter_results]&.each do |linter_result|
      check = LinterCheck.find_or_create_by!(code: linter_result[:code]) do |new_check|
        new_check.name = linter_result[:name]
        new_check.severity = linter_result[:severity]
      end

      file = testrun.submission.file_by_name(linter_result[:file_name])

      LinterCheckRun.create!(
        linter_check: check,
        result: linter_result[:result],
        line: linter_result[:line],
        scope: linter_result[:scope],
        testrun:,
        file:
      )
    rescue ActiveRecord::RecordInvalid
      # Something bad happened. Probably, the RegEx in lib/py_lint_adapter.rb didn't work.
      Sentry.set_extras(testrun: testrun.inspect, linter_result:)
    end
  end
end
