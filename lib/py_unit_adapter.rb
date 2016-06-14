class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \((failures|errors)=(\d+)\)/
  ASSERTION_ERROR_REGEXP = /AssertionError:\s(.*)/

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    count = COUNT_REGEXP.match(output[:stderr]).captures.first.to_i
    matches = FAILURES_REGEXP.match(output[:stderr])
    failed = matches ? matches.captures.try(:second).to_i : 0
    error_matches = ASSERTION_ERROR_REGEXP.match(output[:stderr]).try(:captures) || []
    {count: count, failed: failed, error_messages: error_matches}
  end
end
