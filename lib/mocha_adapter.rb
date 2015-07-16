class MochaAdapter < TestingFrameworkAdapter
  SUCCESS_REGEXP = /(\d+) passing/
  FAILURES_REGEXP = /(\d+) failing/

  def self.framework_name
    'Mocha'
  end

  def parse_output(output)
    matches_success = SUCCESS_REGEXP.match(output[:stdout])
    matches_failed = FAILURES_REGEXP.match(output[:stdout])
    failed = matches_failed ? matches_failed.captures.first.to_i : 0
    success = matches_success ? matches_success.captures.first.to_i : 0
    {count: success+failed, failed: failed}
  end
end
