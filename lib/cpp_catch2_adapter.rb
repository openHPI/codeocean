# frozen_string_literal: true

class CppCatch2Adapter < TestingFrameworkAdapter
  ALL_PASSED_REGEXP   		= /in\s+(\d+)\s+test case/
  COUNT_REGEXP      		  = /test cases:\s+(\d+)/
  FAILURES_REGEXP     		= / \|\s+(\d+)\s+failed/
  ASSERTION_ERROR_REGEXP 	= /\n(.+)error:(.+);/

  def self.framework_name
    'CppCatch2'
  end

  def parse_output(output)
    if ALL_PASSED_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = output[:stdout].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
      failed = output[:stdout].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
      error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP) || []
      {count:, failed:, error_messages: error_matches.flatten.compact_blank}
    end
  end
end
