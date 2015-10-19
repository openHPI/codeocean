class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \(failures=(\d+)\)/

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    count = COUNT_REGEXP.match(output[:stderr]).captures.first.to_i
    matches = FAILURES_REGEXP.match(output[:stderr])
    failed = matches ? matches.captures.try(:first).to_i : 0
    {count: count, failed: failed}
  end
end
