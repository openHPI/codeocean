class CppCatch2Adapter < TestingFrameworkAdapter
  COUNT_REGEXP 	      = /in (\d+) test cases/ 
  FAILURES_REGEXP     = /test cases: (\d+) \| (\d+) failed/
  BOTH_REGEXP		  = /test cases: (\d+) \| (\d+) passed \| (\d+) failed/
  ASSERTION_ERROR_REGEXP = /\n(.+) error:(.+); /

  def self.framework_name
    'CppCatch2'
  end

  def parse_output(output)
    if SUCCESS_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || BOTH_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || BOTH_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      error_matches = ASSERTION_ERROR_REGEXP.match(output[:stdout]).try(:captures) || []
      {count: count, failed: failed, error_messages: error_matches}
    end
  end
end
#array-indices: failed: FAILURES_REGEXP capture[1] BOTH_REGEXP capture[2]
