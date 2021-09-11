# frozen_string_literal: true

class Junit5Adapter < TestingFrameworkAdapter
  COUNT_REGEXP = /(\d+) tests found/.freeze
  FAILURES_REGEXP = /(\d+) tests failed/.freeze
  SUCCESS_REGEXP = /(\d+) tests successful\)/.freeze
  ASSERTION_ERROR_REGEXP = /java\.lang\.AssertionError:?\s(.*?)\torg.junit|org\.junit\.ComparisonFailure:\s(.*?)\torg.junit/m.freeze

  def self.framework_name
    'JUnit 5'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      error_matches = ASSERTION_ERROR_REGEXP.match(output[:stdout]).try(:captures) || []
      {count: count, failed: failed, error_messages: error_matches}
    end
  end
end
