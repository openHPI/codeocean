# frozen_string_literal: true

class RScriptAdapter < TestingFrameworkAdapter
  REGEXP = /(\d+) examples?, (\d+) passed?/
  ASSERTION_ERROR_REGEXP = /AssertionError:\s(.*)/

  def self.framework_name
    'R Script'
  end

  def parse_output(output)
    captures = output[:stdout].scan(REGEXP).try(:last).map(&:to_i)
    count = captures.first
    passed = captures.second
    failed = count - passed
    assertion_error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP) || []
    {count:, failed:, error_messages: assertion_error_matches.flatten.compact_blank}
  end
end
