class JunitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Tests run: (\d+)/
  FAILURES_REGEXP = /Failures: (\d+)/
  SUCCESS_REGEXP = /OK \((\d+) test[s]?\)/

  def self.framework_name
    'JUnit'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      {count: count, failed: failed}
    end
  end
end
