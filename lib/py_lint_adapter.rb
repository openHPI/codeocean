class PyLintAdapter < TestingFrameworkAdapter
  REGEXP = /Your code has been rated at (-?\d+\.?\d*)\/(\d+\.?\d*)/
  ASSERTION_ERROR_REGEXP = /^(.*?\.py):(\d+):(.*?)\(([^,]*?), ([^,]*?),([^,]*?)\) (.*?)$/

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
      passed = captures.first >= 0 ? captures.first : 0
      failed = count - passed
    end

    begin
      assertion_error_matches = Timeout.timeout(2.seconds) do
        output[:stdout].scan(ASSERTION_ERROR_REGEXP).map do |match|
          {
            file_name: match[0].strip,
            line: match[1].to_i,
            severity: match[2].strip,
            code: match[3].strip,
            name: match[4].strip,
            # e.g. function name, nil if outside of a function. Not always available
            scope: match[5].strip.presence,
            result: match[6].strip
          }
        end || []
      end
    rescue Timeout::Error
      assertion_error_matches = []
    end
    concatenated_errors = assertion_error_matches.map { |result| "#{result[:name]}: #{result[:result]}" }.flatten
    {count: count, failed: failed, error_messages: concatenated_errors, detailed_linter_results: assertion_error_matches}
  end
end
