# frozen_string_literal: true

class JuliaAdapter < TestingFrameworkAdapter
  TEST_OUTPUT_REGEXP = /Test Summary:\s+\|\s+(?<test_stat_keys>.*)\n(?<testset>[^|]*)\s+\|\s+(?<test_stat_values>.*)/
  TEST_STATS_REGEXP = /(?<headline>[^|\s]+)/
  ASSERTION_ERROR_REGEXP = /(?<testset>[^:]*): (?<what>.*?) at (?<filename>[^:]*):(?<line>\d+)\s*(?<message>.*?)\s*Stacktrace:/m
  LOAD_ERROR_REGEXP = /ERROR: LoadError: (?<message>.*?)\s*Stacktrace:/m
  def self.framework_name
    'Julia Unit Testing'
  end

  def parse_output(output)
    if output[:stdout].present?
      parse_test_results(output[:stdout])
    else
      parse_error(output[:stderr])
    end
  end

  def parse_test_results(output)
    test_lines = output.to_enum(:scan, TEST_OUTPUT_REGEXP).map { Regexp.last_match } || [{}]
    test_output = test_lines.last

    test_keys_match = test_output[:test_stat_keys].to_s.to_enum(:scan, TEST_STATS_REGEXP).map { Regexp.last_match } || []
    test_values_match = test_output[:test_stat_values].to_enum(:scan, TEST_STATS_REGEXP).map { Regexp.last_match } || []

    test_keys = test_keys_match.map(&:to_s)
    test_values = test_values_match.map(&:to_s)

    # Final variables to be used for further processing:
    _test_set = test_output[:testset]
    test_result = test_keys.zip(test_values).to_h

    # Expected entries in `test_result` are: Pass, Fail, Error, Broken, Total, Time
    # See https://github.com/JuliaLang/julia/blob/ebe1a37af57cb472101d6ede43329ea5ef2e0138/stdlib/Test/src/Test.jl#L1163-L1180

    passed = test_result['Pass'].try(:to_i) || 0
    count = test_result['Total'].try(:to_i) || 0
    failed = test_result[:fail].try(:to_i) || (count - passed) || 0
    if failed.zero?
      {count:, passed: count}
    else
      error_matches = output.to_enum(:scan, ASSERTION_ERROR_REGEXP).map { Regexp.last_match } || []
      messages = error_matches.pluck(:message)
      {count:, failed:, error_messages: messages.flatten.compact_blank}.compact_blank
    end
  end

  def parse_error(output)
    error_matches = output.to_enum(:scan, LOAD_ERROR_REGEXP).map { Regexp.last_match } || []
    messages = error_matches.pluck(:message)
    {count: 1, failed: 1, error_messages: messages.flatten.compact_blank}.compact_blank
  end
end
