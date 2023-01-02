# frozen_string_literal: true

class PyLintAdapter < TestingFrameworkAdapter
  REGEXP = %r{Your code has been rated at (-?\d+\.?\d*)/(\d+\.?\d*)}
  ASSERTION_ERROR_REGEXP = /^(.*?\.py):(\d+):(.*?)\(([^,]*?), ([^,]*?),([^,]*?)\) (.*?)$/

  def self.framework_name
    'PyLint'
  end

  def parse_output(output)
    regex_match = output[:stdout].scan(REGEXP).try(:last)
    if regex_match.blank?
      count = 0
      failed = 0
    else
      captures = regex_match.map(&:to_f)
      count = captures.second
      passed = [captures.first, 0].max
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
              result: match[6].strip,
          }
        end || []
      end
    rescue Timeout::Error
      Sentry.capture_message({stdout: output[:stdout], regex: ASSERTION_ERROR_REGEXP}.to_json)
      assertion_error_matches = []
    end
    concatenated_errors = assertion_error_matches.map {|result| "#{result[:name]}: #{result[:result]}" }
    {
      count:,
      failed:,
      error_messages: concatenated_errors.flatten.compact_blank,
      detailed_linter_results: assertion_error_matches.flatten.compact_blank,
    }
  end

  def self.translate_linter(assessment, locale)
    # The message will be translated once the results were stored in the database
    # See SubmissionScoring for actual function call

    I18n.locale = locale || I18n.default_locale

    return assessment if assessment[:detailed_linter_results].blank?

    assessment[:detailed_linter_results].map! do |message|
      severity = message[:severity]
      name = message[:name]

      message[:severity] = get_t("linter.#{severity}.severity_name", message[:severity])
      message[:name] = get_t("linter.#{severity}.#{name}.name", message[:name])

      regex = get_t("linter.#{severity}.#{name}.regex", nil)&.strip

      if regex.present?
        captures = message[:result].match(Regexp.new(regex))&.named_captures&.symbolize_keys

        if captures.nil?
          Sentry.capture_message({regex:, message: message[:result]}.to_json)
          replacement = {}
        else
          replacement = captures.each do |key, value|
            value&.replace get_t("linter.#{severity}.#{name}.#{key}.#{value}", value)
          end
        end
      else
        replacement = {}
      end

      replacement[:default] = message[:result]
      message[:result] = I18n.t("linter.#{severity}.#{name}.replacement", **replacement)
      message
    end

    assessment[:error_messages] = assessment[:detailed_linter_results].map do |message|
      "#{message[:name]}: #{message[:result]}"
    end

    assessment
  rescue StandardError => e
    # A key was not defined or something really bad happened
    Sentry.set_extras(assessment)
    Sentry.capture_exception(e)
    assessment
  end

  def self.get_t(key, default)
    # key might be "linter.#{severity}.#{name}.#{key}.#{value}"
    # or something like "linter.#{severity}.#{name}.replacement"
    translation = I18n.t(key, default:)
    cleaned_key = key.delete_suffix(".#{default}") # Remove any custom prefix, might have no effect
    keys = cleaned_key.split('.')
    final_key = keys.pop
    log_missing = if %w[actual suggestion context line].include?(final_key)
                    # SyntaxErrors: These are dynamic and won't get translated
                    false
                  else
                    # Read config key
                    I18n.t(keys.append('log_missing').join('.'), default: false)
                  end
    Sentry.capture_message({key: cleaned_key, default:}.to_json) if translation == default && log_missing
    translation
  end
end
