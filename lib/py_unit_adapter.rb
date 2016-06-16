class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \(.*failures=(\d+).*\)/
  ERRORS_REGEXP = /FAILED \(.*errors=(\d+).*\)/
  ASSERTION_ERROR_REGEXP = /AssertionError:\s(.*)/

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    count = COUNT_REGEXP.match(output[:stderr]).captures.first.to_i
    failures_matches = FAILURES_REGEXP.match(output[:stderr])
    failed = failures_matches ? failures_matches.captures.try(:first).to_i : 0
    error_matches = ERRORS_REGEXP.match(output[:stderr])
    errors = error_matches ? error_matches.captures.try(:first).to_i : 0
    assertion_error_matches = ASSERTION_ERROR_REGEXP.match(output[:stderr]).try(:captures) || []
    {count: count, failed: failed + errors, error_messages: assertion_error_matches}
  end
end
