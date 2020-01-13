class RScriptAdapter < TestingFrameworkAdapter
  REGEXP = /(\d+) examples?, (\d+) passed?/
  ASSERTION_ERROR_REGEXP = /AssertionError:\s(.*)/

  def self.framework_name
    'R Script'
  end

  def parse_output(output)
    captures = REGEXP.match(output[:stdout]).captures.map(&:to_i)
    count = captures.first
    passed = captures.second
    failed = count - passed
    assertion_error_matches = output[:stdout].scan(ASSERTION_ERROR_REGEXP).flatten || []
    {count: count, failed: failed, error_messages: assertion_error_matches}
  end
end
