class CppCatch2Adapter < TestingFrameworkAdapter
  ALL_PASSED_REGEXP   		= /in\s+(\d+)\s+test case/ 
  COUNT_REGEXP      		  = /test cases:\s+(\d+)/
  FAILURES_REGEXP     		= / \|\s+(\d+)\s+failed/
  ASSERTION_ERROR_REGEXP 	= /\n(.+)error:(.+);/  

  def self.framework_name
    'CppCatch2'
  end

  def parse_output(output)
    if ALL_PASSED_REGEXP.match(output[:stdout])
      {count: Regexp.last_match(1).to_i, passed: Regexp.last_match(1).to_i}
    else
      count = COUNT_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      failed = FAILURES_REGEXP.match(output[:stdout]).try(:captures).try(:first).try(:to_i) || 0
      error_matches = ASSERTION_ERROR_REGEXP.match(output[:stdout]).try(:captures) || []
      {count: count, failed: failed, error_messages: error_matches}
    end
  end
end
