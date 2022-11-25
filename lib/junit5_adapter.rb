# frozen_string_literal: true

class Junit5Adapter < TestingFrameworkAdapter
  COUNT_REGEXP = /(\d+) tests found/
  FAILURES_REGEXP = /(\d+) tests failed/
  ASSERTION_ERROR_REGEXP = /=> java\.lang\.AssertionError:?\s(.*?)\s*org\.junit|=> org\.junit\.ComparisonFailure:\s(.*?)\s*org\.junit|=>\s(.*?)\s*org\.junit\.internal\.ComparisonCriteria\.arrayEquals|=> org\.opentest4j\.AssertionFailedError:?\s(.*?)\s*org.junit/m

  def self.framework_name
    'JUnit 5'
  end

  def parse_output(output)
    count = output[:stdout].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
    failed = output[:stdout].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
    if failed.zero?
      {count:, passed: count}
    else
      error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP) || []
      {count:, failed:, error_messages: error_matches.flatten.compact_blank}
    end
  end
end
