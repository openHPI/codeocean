class RspecAdapter < TestingFrameworkAdapter
  REGEXP = /(\d+) examples?, (\d+) failures?/

  def self.framework_name
    'RSpec 3'
  end

  def parse_output(output)
    captures = REGEXP.match(output[:stdout]).captures.map(&:to_i)
    count = captures.first
    failed = captures.second
    {count: count, failed: failed}
  end
end
