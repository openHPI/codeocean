# frozen_string_literal: true

class Junit5Adapter < TestingFrameworkAdapter
  COUNT_REGEXP = /(\d+) tests found/.freeze
  FAILURES_REGEXP = /(\d+) tests failed/.freeze
  ASSERTION_ERROR_REGEXP = /java\.lang\.AssertionError:?\s(.*?)\s*org.junit|org\.junit\.ComparisonFailure:\s(.*?)\s*org.junit/m.freeze

  def self.framework_name
    'JUnit 5'
  end

  def parse_output(output)
    count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
    failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
    if failed.zero?
      {count: count, passed: count}
    else
      error_matches = ASSERTION_ERROR_REGEXP.match(output[:stdout]).try(:captures) || []
      {count: count, failed: failed, error_messages: error_matches}
    end
  end
end
