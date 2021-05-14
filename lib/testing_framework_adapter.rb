# frozen_string_literal: true

class TestingFrameworkAdapter
  def augment_output(options = {})
    if !options[:count]
      options.merge(count: options[:failed] + options[:passed])
    elsif !options[:failed]
      options.merge(failed: options[:count] - options[:passed])
    elsif !options[:passed]
      options.merge(passed: options[:count] - options[:failed])
    end
  end
  private :augment_output

  def self.framework_name
    name
  end

  def parse_output(*)
    raise NotImplementedError.new("#{self.class} should implement #parse_output!")
  end
  private :parse_output

  def test_outcome(output)
    augment_output(parse_output(output))
  end
end
