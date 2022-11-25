# frozen_string_literal: true

class SqlResultSetComparatorAdapter < TestingFrameworkAdapter
  MISSING_TUPLES_REGEXP = /Missing tuples: \[\]/
  UNEXPECTED_TUPLES_REGEXP = /Unexpected tuples: \[\]/

  def self.framework_name
    'SqlResultSetComparator'
  end

  def parse_output(output)
    if MISSING_TUPLES_REGEXP.match(output[:stdout]) && UNEXPECTED_TUPLES_REGEXP.match(output[:stdout])
      {count: 1, passed: 1}
    else
      {count: 1, failed: 1}
    end
  end
end
