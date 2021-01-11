class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \(.*failures=(\d+).*\)/
  ERRORS_REGEXP = /FAILED \(.*errors=(\d+).*\)/
  ASSERTION_ERROR_REGEXP = /^(ERROR|FAIL):\ (.*?)\ .*?^[^\.\n]*?(Error|Exception):\s((\s|\S)*?)(>>>.*?)*\s\s(-|=){70}/m

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    count = COUNT_REGEXP.match(output[:stderr]).captures.first.to_i
    failures_matches = FAILURES_REGEXP.match(output[:stderr])
    failed = failures_matches ? failures_matches.captures.try(:first).to_i : 0
    error_matches = ERRORS_REGEXP.match(output[:stderr])
    errors = error_matches ? error_matches.captures.try(:first).to_i : 0
    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stderr].scan(ASSERTION_ERROR_REGEXP).map { |match|
          testname = match[1]
          error = match[3].strip

          if testname == 'test_assess'
            error
          else
            "#{testname}: #{error}"
          end
        }.flatten || []
      end
    rescue Timeout::Error
      Raven.capture_message({stderr: output[:stderr], regex: ASSERTION_ERROR_REGEXP}.to_json)
      assertion_error_matches = []
    end
    {count: count, failed: failed + errors, error_messages: assertion_error_matches}
  end
end
