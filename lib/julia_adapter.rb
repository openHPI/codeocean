# frozen_string_literal: true

class JuliaAdapter < TestingFrameworkAdapter
  COUNT_REGEXP = /(?<testset>[^|\s]*)\s+\|\s+(?<pass>\d+)\s+(?>(?<fail>\d+)\s+)?(?<total>\d+)\s+(?<seconds>\d+\.\d+)s/
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
    test_lines = output.to_enum(:scan, COUNT_REGEXP).map { Regexp.last_match } || [{}]
    test_result = test_lines.last

    passed = test_result[:pass].try(:to_i) || 0
    count = test_result[:total].try(:to_i) || 0
    failed = test_result[:fail].try(:to_i) || (count - passed) || 0
    if failed.zero?
      {count:, passed: count}
    else
      error_matches = output.to_enum(:scan, ASSERTION_ERROR_REGEXP).map { Regexp.last_match } || []
      messages = error_matches.pluck(:message)
      {count:, failed:, error_messages: messages.flatten.compact_blank}
    end
  end

  def parse_error(output)
    error_matches = output.to_enum(:scan, LOAD_ERROR_REGEXP).map { Regexp.last_match } || []
    messages = error_matches.pluck(:message)
    {count: 1, failed: 1, error_messages: messages.flatten.compact_blank}
  end
end
