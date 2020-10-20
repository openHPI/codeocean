class PyLintAdapter < TestingFrameworkAdapter
  REGEXP = /Your code has been rated at (-?\d+\.?\d*)\/(\d+\.?\d*)/
  ASSERTION_ERROR_REGEXP = /^.*?\(.*?,\ (.*?),.*?\)\ (.*?)$/m

  def self.framework_name
    'PyLint'
  end

  def parse_output(output)
    regex_match = REGEXP.match(output[:stdout])
    if regex_match.blank?
      count = 0
      failed = 0
    else
      captures = regex_match.captures.map(&:to_f)
      count = captures.second
      passed = captures.first
      failed = count - passed
    end

    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stdout].scan(ASSERTION_ERROR_REGEXP).map { |match|
          test = match.first.strip
          description = match.second.strip
          "#{test}: #{description}"
        }.flatten || []
      end
    rescue Timeout::Error
      assertion_error_matches = []
    end
    {count: count, failed: failed, error_messages: assertion_error_matches}
  end
end
