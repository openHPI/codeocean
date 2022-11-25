# frozen_string_literal: true

class PyUnitAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /Ran (\d+) test/
  FAILURES_REGEXP = /FAILED \(.*failures=(\d+).*\)/
  ERRORS_REGEXP = /FAILED \(.*errors=(\d+).*\)/
  ASSERTION_ERROR_REGEXP = /^(ERROR|FAIL):\ (.*?)\ .*?^[^.\n]*?(Error|Exception):\s((\s|\S)*?)(>>>[^>]*?)*\s\s(-|=){70}/m

  def self.framework_name
    'PyUnit'
  end

  def parse_output(output)
    # PyUnit is expected to print test results on Stderr!
    count = output[:stderr].scan(COUNT_REGEXP).try(:last).try(:first).try(:to_i) || 0
    failed = output[:stderr].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
    errors = output[:stderr].scan(ERRORS_REGEXP).try(:last).try(:first).try(:to_i) || 0
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
        end || []
      end
    rescue Timeout::Error
      Sentry.capture_message({stderr: output[:stderr], regex: ASSERTION_ERROR_REGEXP}.to_json)
      assertion_error_matches = []
    end
    {count:, failed: failed + errors, error_messages: assertion_error_matches.flatten.compact_blank}
  end
end
