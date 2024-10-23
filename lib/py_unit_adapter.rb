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

    total_failed = failed + errors

    if count < total_failed
      # Catch a weird edge case where the test count is less than the failed count.
      # This might happen in PyUnit, when a test is failing (by design) during the setUpClass phase.
      # In those cases, we might get the following output: Ran 0 tests in 0.001s, FAILED (failures=1)
      # Normally, we would calculate the passed tests as count (0) - failed (1) = passed (-1).
      # In the given scenario, a negative number of passed tests doesn't make sense.
      # Hence, we assume that the count is invalid and increase it by the number of failed tests.
      count += total_failed
    end

    {count:, failed: total_failed, error_messages: assertion_error_matches.flatten.compact_blank.sort}.compact_blank
  end
end
