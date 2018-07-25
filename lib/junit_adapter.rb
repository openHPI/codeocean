class JunitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Tests run: (\d+)/
  FAILURES_REGEXP = /Failures: (\d+)/
  SUCCESS_REGEXP = /OK \((\d+) test[s]?\)/
  ASSERTION_ERROR_REGEXP = /java\.lang\.AssertionError:?\s(.*?)\tat org.junit|org\.junit\.ComparisonFailure:\s(.*?)\tat org.junit/m

  def self.framework_name
    'JUnit'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      error_matches = ASSERTION_ERROR_REGEXP.match(output[:stdout]).try(:captures) || []
      {count: count, failed: failed, error_messages: error_matches}
    end
  end
end
