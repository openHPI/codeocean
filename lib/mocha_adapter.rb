# frozen_string_literal: true

class MochaAdapter < TestingFrameworkAdapter
  SUCCESS_REGEXP = /(\d+) passing/
  FAILURES_REGEXP = /(\d+) failing/

  def self.framework_name
    'Mocha'
  end

  def parse_output(output)
    success = output[:stdout].scan(SUCCESS_REGEXP).try(:last).try(:first).try(:to_i) || 0
    failed = output[:stdout].scan(FAILURES_REGEXP).try(:last).try(:first).try(:to_i) || 0
    {count: success + failed, failed:}
  end
end
