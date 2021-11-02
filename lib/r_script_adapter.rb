# frozen_string_literal: true

class RScriptAdapter < TestingFrameworkAdapter
  REGEXP = /(\d+) examples?, (\d+) passed?/.freeze
  ASSERTION_ERROR_REGEXP = /AssertionError:\s(.*)/.freeze

  def self.framework_name
    'R Script'
  end

  def parse_output(output)
    captures = output[:stdout].scan(REGEXP).try(:last).map(&:to_i)
    count = captures.first
    passed = captures.second
    failed = count - passed
    assertion_error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP) || []
    {count: count, failed: failed, error_messages: assertion_error_matches.flatten.reject(&:blank?)}
  end
end
