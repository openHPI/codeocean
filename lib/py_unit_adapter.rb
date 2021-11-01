# frozen_string_literal: true

class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/.freeze
  FAILURES_REGEXP = /FAILED \(.*failures=(\d+).*\)/.freeze
  ERRORS_REGEXP = /FAILED \(.*errors=(\d+).*\)/.freeze
  ASSERTION_ERROR_REGEXP = /^(ERROR|FAIL):\ (.*?)\ .*?^[^.\n]*?(Error|Exception):\s((\s|\S)*?)(>>>.*?)*\s\s(-|=){70}/m.freeze

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    # PyUnit is expected to print test results on Stderr!
    count = COUNT_REGEXP.match(output[:stderr]).captures.first.to_i
    failures_matches = FAILURES_REGEXP.match(output[:stderr])
    failed = failures_matches ? failures_matches.captures.try(:first).to_i : 0
    error_matches = ERRORS_REGEXP.match(output[:stderr])
    errors = error_matches ? error_matches.captures.try(:first).to_i : 0
    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stderr].scan(ASSERTION_ERROR_REGEXP).map do |match|
          testname = match[1]
          error = match[3].strip

          if testname == 'test_assess'
            error
          else
            "#{testname}: #{error}"
          end
        end.flatten || []
      end
    rescue Timeout::Error
      Sentry.capture_message({stderr: output[:stderr], regex: ASSERTION_ERROR_REGEXP}.to_json)
      assertion_error_matches = []
    end
    {count: count, failed: failed + errors, error_messages: assertion_error_matches}
  end
end
